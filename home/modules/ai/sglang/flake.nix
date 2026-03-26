{
  description = "SGLang Development Environment with Blackwell Optimization";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Global SGLang environment path
      GLOBAL_SGLANG_ENV = "$HOME/.cache/nix-sglang-env";

      # CUDA runtime dependencies
      runtimeLibs = with pkgs; [
        cudaPackages_12.cuda_cudart
        cudaPackages_12.libcublas
        gcc-unwrapped.lib
        stdenv.cc.cc.lib
      ];

      libPath = pkgs.lib.makeLibraryPath runtimeLibs;

    in {
      apps.${system}.sglang-serve = {
        type = "app";
        program = "${pkgs.writeShellScript "sglang-serve" ''
          # Set environment variables
          export CUDA_VISIBLE_DEVICES=0
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          # Start SGLang service - RTX 5090 optimized configuration
          exec "${GLOBAL_SGLANG_ENV}/bin/python" -m sglang.launch_server \
            --model-path GadflyII/GLM-4.7-Flash-NVFP4 \
            --host 127.0.0.1 \
            --port 8020 \
            --tp 1 \
            --mem-fraction-static 0.90 \
            --max-running-requests 256 \
            --trust-remote-code \
            --log-level warning
        ''}";
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "sglang-blackwell-env";

        buildInputs = with pkgs; [
          uv
          python312
          gcc
          cudaPackages_12.cuda_cudart
          cudaPackages_12.libcublas
          cudaPackages_12.cuda_nvcc
        ];

        shellHook = ''
          # Activate global SGLang virtual environment
          if [ -d "${GLOBAL_SGLANG_ENV}" ]; then
            export PATH="${GLOBAL_SGLANG_ENV}/bin:$PATH"
            export VIRTUAL_ENV="${GLOBAL_SGLANG_ENV}"
            echo "✅ SGLang environment activated: ${GLOBAL_SGLANG_ENV}"
          else
            echo "⚠️  SGLang environment does not exist, please run home-manager switch first"
            echo "   or manually create: uv venv ${GLOBAL_SGLANG_ENV} && uv pip install sglang"
          fi

          # 设置环境变量
          export CUDA_VISIBLE_DEVICES=0
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"

          # WSL2 drivers priority, Nix CUDA as fallback
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"

          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          # Display environment information
          echo ""
          echo "🚀 SGLang Blackwell Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Python:       $(python --version 2>&1)"
          echo "CUDA Toolkit: ${pkgs.cudaPackages_12.cuda_cudart.version}"
          echo "SGLang Env:    ${GLOBAL_SGLANG_ENV}"
          echo "HF Mirror:     $HF_ENDPOINT"
          echo ""
          echo "💡 Quick Commands:"
          echo "  python -c 'import sglang; print(sglang.__version__)'  # Check SGLang version"
          echo "  python -c 'import torch; print(torch.cuda.is_available())'  # Check CUDA"
          echo "  nvidia-smi  # Check GPU status"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
        '';
      };
    };
}
