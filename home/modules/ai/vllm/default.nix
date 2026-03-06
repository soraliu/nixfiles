{ pkgs, config, ... }:

let
  # 全局固定路径
  GLOBAL_VLLM_ENV = "${config.home.homeDirectory}/.cache/nix-vllm-env";

  # CUDA 运行时依赖
  runtimeLibs = with pkgs; [
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
  config = {
    home.packages = with pkgs; [
      # vLLM 通过 uv 安装，这里添加系统依赖
      gcc-unwrapped.lib
      stdenv.cc.cc.lib
      cudaPackages_12.cuda_cudart
      cudaPackages_12.libcublas

      # vLLM 包装脚本
      vllmWrapper
    ];

    programs.pm2.services = [{
      name = "vllm-glm4-flash";
      interpreter = "${pkgs.bash}/bin/bash";
      script = "${pkgs.writeShellScript "vllm-pm2-launcher" ''
        # 智能查找 nixfiles 路径
        if [ -n "''${NIXFILES_ROOT:-}" ] && [ -d "$NIXFILES_ROOT/home/modules/ai/vllm" ]; then
          NIXFILES_PATH="$NIXFILES_ROOT"
        elif [ -d "$HOME/Github/nixfiles/home/modules/ai/vllm" ]; then
          NIXFILES_PATH="$HOME/Github/nixfiles"
        elif [ -d "$HOME/nixfiles/home/modules/ai/vllm" ]; then
          NIXFILES_PATH="$HOME/nixfiles"
        elif [ -d "$HOME/.config/home-manager/home/modules/ai/vllm" ]; then
          NIXFILES_PATH="$HOME/.config/home-manager"
        else
          echo "Error: nixfiles repository not found"
          echo "Tried locations:"
          echo "  - \$NIXFILES_ROOT (if set)"
          echo "  - $HOME/Github/nixfiles"
          echo "  - $HOME/nixfiles"
          echo "  - $HOME/.config/home-manager"
          echo ""
          echo "Please set NIXFILES_ROOT environment variable to your nixfiles repository path"
          exit 1
        fi

        cd "$NIXFILES_PATH"
        exec ${pkgs.nix}/bin/nix run --impure ./home/modules/ai/vllm#vllm-serve
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
