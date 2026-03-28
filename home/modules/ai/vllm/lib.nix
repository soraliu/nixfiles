# vLLM 多模型共享基础设施
# PM2 通过 nix run 调用 models/flake.nix 启动模型，避免重复配置
{ pkgs, lib, config }:
let
  # 导入统一配置
  vllmConfig = import ./models/config.nix;

  # 展开 ~ 为实际路径
  vllmModulePath = builtins.replaceStrings ["~"] ["${config.home.homeDirectory}"] vllmConfig.vllmModulePath;

  # CUDA 运行时依赖（用于 mkWrapper）
  runtimeLibs = with pkgs; [
    cudaPackages_12.cuda_cudart
    cudaPackages_12.libcublas
    gcc-unwrapped.lib
    stdenv.cc.cc.lib
  ];

  libPath = lib.makeLibraryPath runtimeLibs;

  # 从 config.nix 生成 pm2 服务配置（通过 nix run 调用 flake.nix）
  mkPm2Service = modelCfg: {
    name = modelCfg.name;
    script = "${pkgs.writeShellScript "pm2-${modelCfg.name}" ''
      exec ${pkgs.nix}/bin/nix run --impure ${vllmModulePath}#${modelCfg.name}
    ''}";
    interpreter = "none";
    cwd = vllmModulePath;
    autorestart = true;
    restart_delay = 5000;
    max_restarts = 3;
    # 注意：移除 wait_ready，因为 CPU 加载模型需要较长时间（可能超过 5 分钟）
    # 模型就绪由 flake.nix 中的健康检查循环保证
    kill_timeout = 600000;
    env = {
      CUDA_VISIBLE_DEVICES = "0";
      HF_HOME = "$HOME/.cache/huggingface";
      HF_ENDPOINT = "https://hf-mirror.com";
      CUDA_CACHE_PATH = "$HOME/.cache/cuda";
      CC = "${pkgs.gcc}/bin/gcc";
    };
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
    packages = runtimeLibs;
  };

in {
  inherit mkPm2Service mkSocatPm2Service mkModels runtimeLibs libPath;
}
