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

      # 全局 SGLang 环境路径
      GLOBAL_SGLANG_ENV = "$HOME/.cache/nix-sglang-env";

      # CUDA 运行时依赖
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
          # 设置环境变量
          export CUDA_VISIBLE_DEVICES=0
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          # 启动 SGLang 服务 - RTX 5090 优化配置
          exec "${GLOBAL_SGLANG_ENV}/bin/python" -m sglang.launch_server \
            --model-path GadflyII/GLM-4.7-Flash-NVFP4 \
            --host 127.0.0.1 \
            --port 8001 \
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
          # 激活全局 SGLang 虚拟环境
          if [ -d "${GLOBAL_SGLANG_ENV}" ]; then
            export PATH="${GLOBAL_SGLANG_ENV}/bin:$PATH"
            export VIRTUAL_ENV="${GLOBAL_SGLANG_ENV}"
            echo "✅ SGLang 环境已激活: ${GLOBAL_SGLANG_ENV}"
          else
            echo "⚠️  SGLang 环境不存在，请先运行 home-manager switch"
            echo "   或手动创建: uv venv ${GLOBAL_SGLANG_ENV} && uv pip install sglang"
          fi

          # 设置环境变量
          export CUDA_VISIBLE_DEVICES=0
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"

          # WSL2 驱动优先，Nix CUDA 作为后备
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"

          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          # 显示环境信息
          echo ""
          echo "🚀 SGLang Blackwell 开发环境"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Python:       $(python --version 2>&1)"
          echo "CUDA Toolkit: ${pkgs.cudaPackages_12.cuda_cudart.version}"
          echo "SGLang 环境:  ${GLOBAL_SGLANG_ENV}"
          echo "HF 镜像:      $HF_ENDPOINT"
          echo ""
          echo "💡 快速命令："
          echo "  python -c 'import sglang; print(sglang.__version__)'  # 检查 SGLang 版本"
          echo "  python -c 'import torch; print(torch.cuda.is_available())'  # 检查 CUDA"
          echo "  nvidia-smi  # 查看 GPU 状态"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
        '';
      };
    };
}
