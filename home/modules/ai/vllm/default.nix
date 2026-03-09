{ pkgs, lib, config, ... }:

let
  # 全局固定路径
  GLOBAL_VLLM_ENV = "${config.home.homeDirectory}/.cache/nix-vllm-env";
  vllmModulePath = "${config.home.homeDirectory}/.cache/vllm-flake";

  isLinux = pkgs.stdenv.isLinux;

  # CUDA 运行时依赖
  runtimeLibs = with pkgs; lib.optionals isLinux [
    # WSL2 驱动（优先级最高）
    # /usr/lib/wsl/lib 在 LD_LIBRARY_PATH 中手动添加

    # Nix CUDA Toolkit（版本锁定）
    cudaPackages_12.cuda_cudart
    cudaPackages_12.libcublas

    # 系统库
    gcc-unwrapped.lib
    stdenv.cc.cc.lib
  ];

  # 构建 LD_LIBRARY_PATH
  libPath = pkgs.lib.makeLibraryPath runtimeLibs;

  # vLLM 包装脚本，自动设置 LD_LIBRARY_PATH
  vllmWrapper = pkgs.writeShellScriptBin "vllm" ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
    exec "${GLOBAL_VLLM_ENV}/bin/vllm" "$@"
  '';

in {
  config = lib.mkIf isLinux {
    # 创建符号链接：将 vllm 模块链接到缓存目录
    home.file."${vllmModulePath}".source = ./.;

    home.packages = runtimeLibs ++ [
      vllmWrapper
    ];

    programs.pm2.services = [{
      name = "vllm-glm4-flash";
      interpreter = "${pkgs.bash}/bin/bash";
      script = "${pkgs.writeShellScript "vllm-pm2-launcher" ''
        cd "${vllmModulePath}"
        exec ${pkgs.nix}/bin/nix run --impure .#vllm-serve
      ''}";
      cwd = config.home.homeDirectory;
      exp_backoff_restart_delay = 5000;
      max_restarts = 3;
      min_uptime = 10000;
    }];

    # 初始化脚本（使用全局路径）
    home.activation.initVllm = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      VLLM_ENV="${GLOBAL_VLLM_ENV}"

      if [ ! -d "$VLLM_ENV" ]; then
        echo "Creating vLLM environment at $VLLM_ENV..."
        ${pkgs.uv}/bin/uv venv "$VLLM_ENV"
        echo "Installing vLLM..."
        cd "$VLLM_ENV" && ${pkgs.uv}/bin/uv pip install vllm
      fi

      # 创建 CUDA 缓存目录
      mkdir -p "${config.home.homeDirectory}/.cache/cuda"
    '';
  };
}
