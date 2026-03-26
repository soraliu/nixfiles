{ pkgs, lib, config, ... }:

let
  GLOBAL_SGLANG_ENV = "${config.home.homeDirectory}/.cache/nix-sglang-env";
  sglangModulePath = "${config.home.homeDirectory}/.cache/sglang-flake";

  isLinux = pkgs.stdenv.isLinux;

  # CUDA 运行时依赖
  # TODO: 抽取到 ai/cuda-lib.nix 与 vllm 共享
  runtimeLibs = with pkgs; [
    cudaPackages_12.cuda_cudart
    cudaPackages_12.libcublas
    gcc-unwrapped.lib
    stdenv.cc.cc.lib
  ];

  libPath = lib.makeLibraryPath runtimeLibs;

  # SGLang wrapper（通用 CLI 入口）
  sglangWrapper = pkgs.writeShellScriptBin "sglang" ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
    exec "${GLOBAL_SGLANG_ENV}/bin/python" -m sglang.launch_server "$@"
  '';

  # SGLang 启动脚本（直接执行，不依赖 nix run）
  sglangServeScript = pkgs.writeShellScript "sglang-serve-glm4-flash" ''
    export CUDA_VISIBLE_DEVICES=0
    export HF_HOME="$HOME/.cache/huggingface"
    export HF_ENDPOINT="https://hf-mirror.com"
    export CUDA_CACHE_PATH="$HOME/.cache/cuda"
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
    export CC="${pkgs.gcc}/bin/gcc"
    export CXX="${pkgs.gcc}/bin/g++"

    exec "${GLOBAL_SGLANG_ENV}/bin/python" -m sglang.launch_server \
      --model-path GadflyII/GLM-4.7-Flash-NVFP4 \
      --host 127.0.0.1 \
      --port 8020 \
      --tp 1 \
      --mem-fraction-static 0.90 \
      --max-running-requests 256 \
      --trust-remote-code \
      --log-level warning
  '';

in {
  config = lib.mkIf isLinux {
    # 顶层 symlink，用于 nix run 调试入口
    home.file."${sglangModulePath}".source = ./.;

    home.packages = runtimeLibs ++ [
      sglangWrapper
    ];

    # systemd user service（手动启动，不 autostart）
    systemd.user.services.sglang-glm4-flash = {
      Unit = {
        Description = "SGLang Model Server - GLM-4.7-Flash";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${sglangServeScript}";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStartSec = 300;
      };
      Install = {
        WantedBy = [];
      };
    };

    home.activation.initSglang = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      SGLANG_ENV="${GLOBAL_SGLANG_ENV}"

      if [ ! -d "$SGLANG_ENV" ]; then
        echo "Creating SGLang environment at $SGLANG_ENV..."
        ${pkgs.uv}/bin/uv venv "$SGLANG_ENV"
        echo "Installing SGLang..."
        cd "$SGLANG_ENV" && ${pkgs.uv}/bin/uv pip install sglang
      fi

      mkdir -p "${config.home.homeDirectory}/.cache/cuda"
    '';
  };
}
