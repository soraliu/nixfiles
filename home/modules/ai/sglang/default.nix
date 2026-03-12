{ pkgs, config, ... }:

let
  # Global fixed path
  GLOBAL_SGLANG_ENV = "${config.home.homeDirectory}/.cache/nix-sglang-env";
  sglangModulePath = "${config.home.homeDirectory}/.cache/sglang-flake";

  # CUDA runtime dependencies
  runtimeLibs = with pkgs; [
    # WSL2 drivers (highest priority)
    # /usr/lib/wsl/lib manually added to LD_LIBRARY_PATH

    # Nix CUDA Toolkit (version locked)
    cudaPackages_12.cuda_cudart
    cudaPackages_12.libcublas

    # System libraries
    gcc-unwrapped.lib
    stdenv.cc.cc.lib
  ];

  # Build LD_LIBRARY_PATH
  libPath = pkgs.lib.makeLibraryPath runtimeLibs;

  # SGLang wrapper script, automatically sets LD_LIBRARY_PATH
  sglangWrapper = pkgs.writeShellScriptBin "sglang" ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
    exec "${GLOBAL_SGLANG_ENV}/bin/python" -m sglang.launch_server "$@"
  '';

in {
  config = {
    # Create symbolic link: link sglang module to cache directory
    home.file."${sglangModulePath}".source = ./.;

    home.packages = with pkgs; [
      # SGLang installed via uv, add system dependencies here
      gcc-unwrapped.lib
      stdenv.cc.cc.lib
      cudaPackages_12.cuda_cudart
      cudaPackages_12.libcublas

      # SGLang wrapper script
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

    # Initialization script (using global path)
    home.activation.initSglang = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      SGLANG_ENV="${GLOBAL_SGLANG_ENV}"

      if [ ! -d "$SGLANG_ENV" ]; then
        echo "Creating SGLang environment at $SGLANG_ENV..."
        ${pkgs.uv}/bin/uv venv "$SGLANG_ENV"
        echo "Installing SGLang..."
        cd "$SGLANG_ENV" && ${pkgs.uv}/bin/uv pip install sglang
      fi

      # Create CUDA cache directory
      mkdir -p "${config.home.homeDirectory}/.cache/cuda"
    '';
  };
}
