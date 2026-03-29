# vLLM 多模型共享基础设施
# PM2 通过 nix run 调用 models/flake.nix 启动模型，避免重复配置
{ pkgs, lib, config }:
let
  # 导入统一配置
  vllmConfig = import ./models/config.nix;

  # 展开 ~ 为实际路径
  vllmModulePath = builtins.replaceStrings ["~"] ["${config.home.homeDirectory}"] vllmConfig.vllmModulePath;

  # ========== 版本管理函数 ==========

  # 生成版本字符串用于 hash（只包含指定的版本）
  mkVersionString = pythonDeps:
    let
      vllm = pythonDeps.vllm or "latest";
      parts = [ "vllm-${vllm}" ]
        ++ lib.optional (pythonDeps ? torch) "torch-${pythonDeps.torch}"
        ++ lib.optional (pythonDeps ? transformers) "transformers-${pythonDeps.transformers}";
    in lib.concatStringsSep "-" parts;

  # 生成 venv hash（SHA256 前 8 位）
  mkVenvHash = pythonDeps:
    builtins.substring 0 8 (builtins.hashString "sha256" (mkVersionString pythonDeps));

  # 生成 override 文件内容
  mkOverrideContent = pythonDeps:
    let
      lines = []
        ++ lib.optional (pythonDeps ? torch) "torch==${pythonDeps.torch}"
        ++ lib.optional (pythonDeps ? transformers) "transformers==${pythonDeps.transformers}";
    in lib.concatStringsSep "\n" lines;

  # 获取模型的 venv 配置
  getVenvConfig = baseDir: modelCfg:
    let
      pythonDeps = modelCfg.pythonDeps or {};
      hash = mkVenvHash pythonDeps;
      venvPath = "${baseDir}/vllm-venv-${hash}";
      overrideContent = mkOverrideContent pythonDeps;
    in {
      inherit venvPath pythonDeps;
      venvHash = hash;
      overrideContent = overrideContent;
      hasOverride = overrideContent != "";
    };

  # 按 venv 分组模型
  groupModelsByVenv = baseDir: models:
    let
      addVenvConfig = m: m // {
        venvConfig = getVenvConfig baseDir m.cfg;
      };
      modelsWithVenv = map addVenvConfig models;
    in
      lib.groupBy (m: m.venvConfig.venvPath) modelsWithVenv;


  # 从 config.nix 生成 pm2 服务配置（通过 nix run 调用 flake.nix）
  mkPm2Service = modelCfg:
    let
      delaySeconds = if modelCfg ? delay then (modelCfg.delay / 1000) else 0;
    in {
      name = modelCfg.name;
      script = "${pkgs.writeShellScript "pm2-${modelCfg.name}" ''
        ${if modelCfg ? delay then ''
          remaining=${toString delaySeconds}
          while [ $remaining -gt 0 ]; do
            echo "[${modelCfg.name}] 延迟启动倒计时: $remaining 秒"
            sleep 3
            remaining=$((remaining - 3))
          done
          echo "[${modelCfg.name}] 开始启动模型..."
        '' else ""}
        exec ${pkgs.nix}/bin/nix run --impure ${vllmModulePath}#${modelCfg.name}
      ''}";
      interpreter = "none";
      cwd = vllmModulePath;
      autorestart = false;
      min_uptime = 300000;       # 应用需运行 5m 才算稳定启动
      restart_delay = 15000;     # 重启前等待 15 秒
      max_restarts = 3;          # 最多 3 次不稳定重启
      kill_timeout = 600000;
    };

  # 从 config.nix 生成 socat 转发脚本
  # socat 绑定到 0.0.0.0，允许内网其他节点访问
  mkSocatScript = modelCfg:
    let
      socatPort = modelCfg.socat-port or (builtins.floor (builtins.fromJSON (toString modelCfg.port)) + 1);
    in
    pkgs.writeShellScriptBin "socat-${modelCfg.name}" ''
      exec ${pkgs.socat}/bin/socat TCP-LISTEN:${toString socatPort},bind=0.0.0.0,fork TCP:10.255.255.254:${toString modelCfg.port}
    '';

  # 从 config.nix 生成 socat pm2 服务配置
  mkSocatPm2Service = modelCfg: {
    name = "socat-${modelCfg.name}";
    script = "${mkSocatScript modelCfg}/bin/socat-${modelCfg.name}";
    interpreter = "none";
    autorestart = true;
    restart_delay = 5000;
    max_restarts = 10;
  };

  # 聚合多个模型配置
  mkModels = models: {
    pm2Services = map (m: mkPm2Service m.cfg) models ++
                  map (m: mkSocatPm2Service m.cfg) models;
    socatScripts = map (m: mkSocatScript m.cfg) models;
  };

in {
  inherit mkPm2Service mkSocatPm2Service mkModels;
  inherit mkVersionString mkVenvHash mkOverrideContent getVenvConfig groupModelsByVenv;
}
