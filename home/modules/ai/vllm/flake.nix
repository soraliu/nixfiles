{
  description = "vLLM Development Environment with Blackwell Optimization";

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

      # 全局 vLLM 环境路径
      GLOBAL_VLLM_ENV = "$HOME/.cache/nix-vllm-env";

      # CUDA 运行时依赖
      runtimeLibs = with pkgs; [
        cudaPackages_12.cuda_cudart
        cudaPackages_12.libcublas
        gcc-unwrapped.lib
        stdenv.cc.cc.lib
      ];

      libPath = pkgs.lib.makeLibraryPath runtimeLibs;

    in {
      apps.${system}.vllm-serve = {
        type = "app";
        program = "${pkgs.writeShellScript "vllm-serve" ''
          # 设置环境变量
          export CUDA_VISIBLE_DEVICES=0
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          echo "启动 vLLM 服务..."
          echo "模型加载中，服务就绪前请求会超时，请等待 ready 提示"

          # 后台轮询健康检查
          (
            while ! ${pkgs.curl}/bin/curl -sf http://127.0.0.1:8000/health >/dev/null 2>&1; do
              sleep 2
            done
            echo ""
            echo "vLLM 服务已就绪 - http://0.0.0.0:8000"
          ) &

          # 启动 vLLM 服务 - RTX 5090 优化配置
          exec "${GLOBAL_VLLM_ENV}/bin/python" -m vllm.entrypoints.openai.api_server \
            --model GadflyII/GLM-4.7-Flash-NVFP4 \
            --max-num-seqs 256 \
            --max-model-len 32768 \
            --gpu-memory-utilization 0.85 \
            --port 8000 \
            --host 0.0.0.0 \
            --trust-remote-code \
            --disable-log-requests \
            --kv-cache-dtype auto \
            --enable-prefix-caching \
            --enable-chunked-prefill \
            --max-num-batched-tokens 32768 \
            --tensor-parallel-size 1 \
            --pipeline-parallel-size 1 \
            --block-size 16 \
            --enable-auto-tool-choice \
            --tool-call-parser glm47
        ''}";
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "vllm-blackwell-env";

        buildInputs = with pkgs; [
          uv
          python312
          gcc
          cudaPackages_12.cuda_cudart
          cudaPackages_12.libcublas
          cudaPackages_12.cuda_nvcc  # 开发工具
        ];

        shellHook = ''
          # 激活全局 vLLM 虚拟环境
          if [ -d "${GLOBAL_VLLM_ENV}" ]; then
            # 直接设置 PATH，不使用 source activate
            export PATH="${GLOBAL_VLLM_ENV}/bin:$PATH"
            export VIRTUAL_ENV="${GLOBAL_VLLM_ENV}"
            echo "✅ vLLM 环境已激活: ${GLOBAL_VLLM_ENV}"
          else
            echo "⚠️  vLLM 环境不存在，请先运行 home-manager switch"
            echo "   或手动创建: uv venv ${GLOBAL_VLLM_ENV} && uv pip install vllm"
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
          echo "🚀 vLLM Blackwell 开发环境"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Python:       $(python --version 2>&1)"
          echo "CUDA Toolkit: ${pkgs.cudaPackages_12.cuda_cudart.version}"
          echo "vLLM 环境:    ${GLOBAL_VLLM_ENV}"
          echo "HF 镜像:      $HF_ENDPOINT"
          echo ""
          echo "💡 快速命令："
          echo "  python -c 'import vllm; print(vllm.__version__)'  # 检查 vLLM 版本"
          echo "  python -c 'import torch; print(torch.cuda.is_available())'  # 检查 CUDA"
          echo "  nvidia-smi  # 查看 GPU 状态"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
        '';
      };
    };
}
