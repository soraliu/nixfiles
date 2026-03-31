{ pkgs, lib }:

let
  vllmConfig = import ./config.nix;
  vllmModulePath = vllmConfig.vllmModulePath;

  mkVersionString = pythonDeps:
    let
      vllm = pythonDeps.vllm or "latest";
      parts = [ "vllm-${vllm}" ]
        ++ lib.optional (pythonDeps ? torch) "torch-${pythonDeps.torch}"
        ++ lib.optional (pythonDeps ? transformers) "transformers-${pythonDeps.transformers}";
    in lib.concatStringsSep "-" parts;

  mkVenvHash = pythonDeps:
    builtins.substring 0 8 (builtins.hashString "sha256" (mkVersionString pythonDeps));

  mkOverrideContent = pythonDeps:
    let
      lines = []
        ++ lib.optional (pythonDeps ? torch) "torch==${pythonDeps.torch}"
        ++ lib.optional (pythonDeps ? transformers) "transformers==${pythonDeps.transformers}";
    in lib.concatStringsSep "\n" lines;

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

  groupModelsByVenv = baseDir: models:
    let
      addVenvConfig = m: m // { venvConfig = getVenvConfig baseDir m.cfg; };
      modelsWithVenv = map addVenvConfig models;
    in lib.groupBy (m: m.venvConfig.venvPath) modelsWithVenv;

  mkPm2Service = vllmModulePath: modelCfg:
    let delaySeconds = if modelCfg ? delay then (modelCfg.delay / 1000) else 0;
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
        exec ${pkgs.nix}/bin/nix run --impure --no-sandbox ${vllmModulePath}#${modelCfg.name}
      ''}";
      interpreter = "none";
      autorestart = true;
      min_uptime = 300000;
      restart_delay = 15000;
      max_restarts = 3;
      kill_timeout = 600000;
    };

  mkSocatScript = modelCfg:
    let
      socatPort = modelCfg.socat-port or (builtins.floor (builtins.fromJSON (toString modelCfg.port)) + 1);
    in pkgs.writeShellScriptBin "socat-${modelCfg.name}" ''
      exec ${pkgs.socat}/bin/socat TCP-LISTEN:${toString socatPort},bind=0.0.0.0,fork TCP:10.255.255.254:${toString modelCfg.port}
    '';

  mkSocatPm2Service = modelCfg: {
    name = "socat-${modelCfg.name}";
    script = "${mkSocatScript modelCfg}/bin/socat-${modelCfg.name}";
    interpreter = "none";
    autorestart = true;
    restart_delay = 5000;
    max_restarts = 10;
  };

  mkModels = vllmModulePath: models: {
    pm2Services = map (m: mkPm2Service vllmModulePath m.cfg) models ++
                  map (m: mkSocatPm2Service m.cfg) models;
    socatScripts = map (m: mkSocatScript m.cfg) models;
  };

in {
  inherit mkPm2Service mkSocatPm2Service mkModels;
  inherit mkVersionString mkVenvHash mkOverrideContent getVenvConfig groupModelsByVenv;
  inherit vllmConfig vllmModulePath;
}
