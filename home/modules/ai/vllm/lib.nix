# vLLM 多模型共享基础设施
# 在 home-manager 上下文中使用（非 flake 沙箱），可自由 import
# 注意：GLOBAL_VLLM_ENV 路径依赖 config.home.homeDirectory 与 $HOME 一致
# 在标准 WSL2 单用户环境下两者一致，如果 $HOME 被覆盖可能不一致
{ pkgs, lib, config }:
let
  GLOBAL_VLLM_ENV = "${config.home.homeDirectory}/.cache/nix-vllm-env";

  # CUDA 运行时依赖
  runtimeLibs = with pkgs; [
    cudaPackages_12.cuda_cudart
    cudaPackages_12.libcublas
    gcc-unwrapped.lib
    stdenv.cc.cc.lib
  ];

  libPath = lib.makeLibraryPath runtimeLibs;

  # vLLM 默认启动参数
  defaultArgs = [
    "--host 0.0.0.0"
    "--trust-remote-code"
    "--disable-log-requests"
    "--kv-cache-dtype auto"
    "--tensor-parallel-size 1"
    "--pipeline-parallel-size 1"
    "--block-size 16"
  ];

  # 从 config.nix 生成完整的 vLLM 启动脚本
  mkServeScript = modelCfg:
    let
      allArgs = defaultArgs ++ (modelCfg.extraArgs or []);
    in
    pkgs.writeShellScript "vllm-serve-${modelCfg.name}" ''
      export CUDA_VISIBLE_DEVICES=0
      export HF_HOME="$HOME/.cache/huggingface"
      export HF_ENDPOINT="https://hf-mirror.com"
      export CUDA_CACHE_PATH="$HOME/.cache/cuda"
      export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
      export CC="${pkgs.gcc}/bin/gcc"
      export CXX="${pkgs.gcc}/bin/g++"

      echo "启动 vLLM: ${modelCfg.name} (port ${toString modelCfg.port})"

      # 后台健康检查
      (
        while ! ${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString modelCfg.port}/health >/dev/null 2>&1; do
          sleep 2
        done
        echo "vLLM 服务已就绪 - ${modelCfg.name} @ http://0.0.0.0:${toString modelCfg.port}"
      ) &

      exec "${GLOBAL_VLLM_ENV}/bin/python" -m vllm.entrypoints.openai.api_server \
        --model ${modelCfg.model} \
        --port ${toString modelCfg.port} \
        --max-num-seqs ${toString (modelCfg.max-num-seqs or 256)} \
        --max-model-len ${toString modelCfg.max-model-len} \
        --gpu-memory-utilization ${toString modelCfg.gpu-memory-utilization} \
        ${lib.concatStringsSep " \\\n        " allArgs}
    '';

  # 从 config.nix 生成 systemd user service
  mkSystemdService = modelCfg: {
    Unit = {
      Description = "vLLM Model Server - ${modelCfg.name}";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${mkServeScript modelCfg}";
      Restart = "on-failure";
      RestartSec = 5;
      # vLLM 模型加载需要较长时间
      TimeoutStartSec = 300;
    };
    Install = {
      WantedBy = if (modelCfg.autostart or true) then [ "default.target" ] else [];
    };
  };

  # 从 config.nix 生成 per-model wrapper script
  mkWrapper = modelCfg:
    pkgs.writeShellScriptBin "${modelCfg.name}" ''
      export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
      exec "${GLOBAL_VLLM_ENV}/bin/vllm" "$@"
    '';

  # 聚合多个模型配置
  mkModels = models: {
    systemdServices = lib.listToAttrs (map (m: {
      name = m.cfg.name;
      value = mkSystemdService m.cfg;
    }) models);
    wrappers = map (m: mkWrapper m.cfg) models;
    packages = runtimeLibs;
  };

in {
  inherit mkServeScript mkSystemdService mkWrapper mkModels runtimeLibs libPath GLOBAL_VLLM_ENV;
}
