{ pkgs, config, ... }:

let
  # 全局固定路径
  GLOBAL_SGLANG_ENV = "${config.home.homeDirectory}/.cache/nix-sglang-env";
  sglangModulePath = "${config.home.homeDirectory}/.cache/sglang-flake";

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

  # SGLang 包装脚本，自动设置 LD_LIBRARY_PATH
  sglangWrapper = pkgs.writeShellScriptBin "sglang" ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
    exec "${GLOBAL_SGLANG_ENV}/bin/python" -m sglang.launch_server "$@"
  '';

in {
  config = {
    # 创建符号链接：将 sglang 模块链接到缓存目录
    home.file."${sglangModulePath}".source = ./.;

    home.packages = with pkgs; [
      # SGLang 通过 uv 安装，这里添加系统依赖
      gcc-unwrapped.lib
      stdenv.cc.cc.lib
      cudaPackages_12.cuda_cudart
      cudaPackages_12.libcublas

      # SGLang 包装脚本
      sglangWrapper
    ];

    programs.pm2.services = [{
      name = "sglang-glm4-flash";
      interpreter = "${pkgs.bash}/bin/bash";
      script = "${pkgs.writeShellScript "sglang-pm2-launcher" ''
        cd "${sglangModulePath}"
        exec ${pkgs.nix}/bin/nix run --impure .#sglang-serve
      ''}";
      cwd = config.home.homeDirectory;
      exp_backoff_restart_delay = 5000;
      max_restarts = 3;
      min_uptime = 10000;
    }];

    # 初始化脚本（使用全局路径）
    home.activation.initSglang = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      SGLANG_ENV="${GLOBAL_SGLANG_ENV}"

      if [ ! -d "$SGLANG_ENV" ]; then
        echo "Creating SGLang environment at $SGLANG_ENV..."
        ${pkgs.uv}/bin/uv venv "$SGLANG_ENV"
        echo "Installing SGLang..."
        cd "$SGLANG_ENV" && ${pkgs.uv}/bin/uv pip install sglang
      fi

      # 创建 CUDA 缓存目录
      mkdir -p "${config.home.homeDirectory}/.cache/cuda"
    '';
  };
}
