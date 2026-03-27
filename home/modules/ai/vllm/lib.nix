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
  # 注意：V1 模式下 --disable-frontend-multiprocessing 在 WSL2 有 loopback 兼容性问题
  # 服务实际通过 10.255.255.254:PORT 访问，nginx 反代提供 0.0.0.0:PORT 的通用访问
  defaultArgs = [
    "--host 0.0.0.0"
    "--trust-remote-code"
    # 可考虑 auto, 但是 fp8 性能更好
    "--kv-cache-dtype fp8"
    # 单卡默认设置1
    "--tensor-parallel-size 1"
    "--pipeline-parallel-size 1"
    # 每一个物理块中可以存放多少个 Token 的 KV 数据
    "--block-size 16"
    # 禁用前端多进程，规避 WSL 兼容性异常
    "--disable-frontend-multiprocessing"
    # Blackwell (SM_120) 稳定性优化
    "--enforce-eager"
    "--num-revision 1"
  ];

  # 从 config.nix 生成完整的 vLLM 启动脚本
  mkServeScript = modelCfg:
    let
      allArgs = defaultArgs ++ (modelCfg.extraArgs or []);
    in
    pkgs.writeShellScriptBin "vllm-serve-${modelCfg.name}" ''
      export CUDA_VISIBLE_DEVICES=0
      export HF_HOME="$HOME/.cache/huggingface"
      export HF_ENDPOINT="https://hf-mirror.com"
      export CUDA_CACHE_PATH="$HOME/.cache/cuda"
      export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
      export CC="${pkgs.gcc}/bin/gcc"
      export CXX="${pkgs.gcc}/bin/g++"

      # 禁用 inductor autotune，大幅减少启动时间（从 ~20min 降到 ~5min）
      export VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE=0
      export VLLM_ENABLE_INDUCTOR_COORDINATE_DESCENT_TUNING=0

      # RTX 5090 Blackwell (sm_120) 稳定性优化
      # 使用 CUDA toolkit 中的 ptxas 替代 triton 内置版本
      if [ -n "$(which nvcc 2>/dev/null)" ]; then
        export TRITON_PTXAS_PATH="$(dirname $(which nvcc))/ptxas)"
      fi

      echo "启动 vLLM: ${modelCfg.name} (port ${toString modelCfg.port})"

      # 后台健康检查（双探针：/health + /v1/models）
      # 注意：vLLM V1 模式下 127.0.0.1 有连接问题，使用 10.255.255.254（WSL2 loopback alias）
      (
        while true; do
          HEALTH_OK=$(${pkgs.curl}/bin/curl -sf http://10.255.255.254:${toString modelCfg.port}/health >/dev/null 2>&1 && echo "yes" || echo "no")
          MODELS_OK=$(${pkgs.curl}/bin/curl -sf http://10.255.255.254:${toString modelCfg.port}/v1/models >/dev/null 2>&1 && echo "yes" || echo "no")
          if [ "$HEALTH_OK" = "yes" ] && [ "$MODELS_OK" = "yes" ]; then
            echo "vLLM 服务已就绪 - ${modelCfg.name} @ http://0.0.0.0:${toString modelCfg.port}"
            break
          fi
          sleep 2
        done
      ) &

      # 启动 vLLM 服务
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

  # 从 config.nix 生成 socat 转发脚本
  # socat 绑定到 0.0.0.0，允许内网其他节点访问
  mkSocatScript = modelCfg:
    let
      socatPort = modelCfg.socat-port or (builtins.floor (builtins.fromJSON (toString modelCfg.port)) + 1);
    in
    pkgs.writeShellScriptBin "socat-${modelCfg.name}" ''
      exec ${pkgs.socat}/bin/socat TCP-LISTEN:${toString socatPort},bind=0.0.0.0,fork TCP:10.255.255.254:${toString modelCfg.port}
    '';

  # 从 config.nix 生成独立的 socat systemd user service
  mkSocatService = modelCfg: {
    Unit = {
      Description = "socat forwarder for ${modelCfg.name}";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${mkSocatScript modelCfg}";
      Restart = "on-failure";
      RestartSec = 5;
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
    }) models) // lib.listToAttrs (map (m: {
      name = "socat-${m.cfg.name}";
      value = mkSocatService m.cfg;
    }) models);
    wrappers = map (m: mkWrapper m.cfg) models;
    serveScripts = map (m: mkServeScript m.cfg) models;
    socatScripts = map (m: mkSocatScript m.cfg) models;
    packages = runtimeLibs;
  };

in {
  inherit mkServeScript mkSystemdService mkSocatService mkWrapper mkModels runtimeLibs libPath GLOBAL_VLLM_ENV;
}
