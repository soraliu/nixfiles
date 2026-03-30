{
  description = "vLLM 多模型服务 — RTX 5090 + uv 环境";

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

      # CUDA 运行时依赖（nix 管理系统库）
      runtimeLibs = with pkgs; [
        cudaPackages.cuda_cudart
        cudaPackages.libcublas
        cudaPackages.cuda_nvcc
        gcc-unwrapped.lib
        stdenv.cc.cc.lib
      ];

      libPath = pkgs.lib.makeLibraryPath runtimeLibs;

      # 导入所有模型配置
      modelConfigs = [
        (import ./glm-4.7-flash/config.nix)
        (import ./qwen3.5-35b-a3b-nvfp4/config.nix)
        (import ./qwen3-vl-8b-instruct/config.nix)
        (import ./qwen3-embedding-0.6b/config.nix)
        (import ./qwen3-vl-embedding-2b/config.nix)
        (import ./qwen3-vl-embedding-8b/config.nix)

      ];

      # vLLM 默认启动参数
      defaultArgs = [
        "--host 0.0.0.0"
        "--trust-remote-code"
        "--tensor-parallel-size 1"
        "--pipeline-parallel-size 1"
      ];

      # 生成调用 uv 环境的启动脚本
      mkVllmRunner = cfg:
        let
          pythonDeps = cfg.pythonDeps or {};

          # 计算 venv hash（与 lib.nix 保持一致）
          vllm = pythonDeps.vllm or "0.18.0";
          versionParts = [ "vllm-${vllm}" ]
            ++ pkgs.lib.optional (pythonDeps ? torch) "torch-${pythonDeps.torch}"
            ++ pkgs.lib.optional (pythonDeps ? transformers) "transformers-${pythonDeps.transformers}";
          versionString = pkgs.lib.concatStringsSep "-" versionParts;
          venvHash = builtins.substring 0 8 (builtins.hashString "sha256" versionString);

          venvPath = "$HOME/.cache/vllm-venv-${venvHash}";
          allArgs = defaultArgs ++ (cfg.extraArgs or []);
        in pkgs.writeShellScript "vllm-run-${cfg.name}" ''
          set -euo pipefail

          VENV_PATH="${venvPath}"

          if [ ! -d "$VENV_PATH" ]; then
            echo "错误: venv 不存在: $VENV_PATH"
            echo "请运行: home-manager switch"
            exit 1
          fi

          # 环境变量
          export CUDA_VISIBLE_DEVICES=0
          export CUDA_MODULE_LOADING=LAZY
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:''${LD_LIBRARY_PATH:-}"
          export LD_PRELOAD="/usr/lib/wsl/lib/libcuda.so"
          export CC="${pkgs.gcc}/bin/gcc";
          export PATH="/usr/lib/wsl/lib:/usr/bin:$PATH"


          # 使用 Nix 提供的 CUDA_HOME
          if [ -z "''${CUDA_HOME:-}" ]; then
            export CUDA_HOME="${pkgs.cudaPackages.cuda_nvcc}"
          fi
          export TRITON_PTXAS_PATH="$CUDA_HOME/ptxas"

          # vLLM 优化
          export VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE=0
          export VLLM_ENABLE_INDUCTOR_COORDINATE_DESCENT_TUNING=0
          export PYTORCH_ALLOC_CONF=expandable_segments:True

          # FlashInfer FP4 MoE 内核（Blackwell 优化）
          # export VLLM_USE_FLASHINFER_MOE_FP4=1
          export CPLUS_INCLUDE_PATH="${pkgs.cudaPackages.cuda_cudart.dev}/include:$CPLUS_INCLUDE_PATH"

          source "$VENV_PATH/bin/activate"

          echo "启动 vLLM: ${cfg.name} (port ${toString cfg.port}, venv: ${venvHash})"

          # 启动 vLLM
          exec python -m vllm.entrypoints.openai.api_server \
            --model ${cfg.model} \
            --port ${toString cfg.port} \
            --max-num-seqs ${toString (cfg.max-num-seqs or 256)} \
            --max-model-len ${toString cfg.max-model-len} \
            --gpu-memory-utilization ${toString cfg.gpu-memory-utilization} \
            ${pkgs.lib.concatStringsSep " \\\n            " allArgs}
        '';

      # 为单个模型生成 flake app
      mkApp = cfg: {
        type = "app";
        program = "${mkVllmRunner cfg}";
      };

      # 生成所有模型的 apps
      modelApps = builtins.listToAttrs (map (cfg: {
        name = cfg.name;
        value = mkApp cfg;
      }) modelConfigs);

    in {
      apps.${system} = modelApps;

      devShells.${system}.default = pkgs.mkShell {
        name = "vllm-uv-env";

        buildInputs = with pkgs; [
          uv
          curl
          gcc
        ] ++ runtimeLibs;

        shellHook = ''
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:''${LD_LIBRARY_PATH:-}"

          # 使用 Nix CUDA
          export CUDA_HOME="${pkgs.cudaPackages.cuda_nvcc}"

          echo ""
          echo "vLLM + uv 开发环境"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "venv 基础目录: ~/.cache/vllm-venv-*"
          echo "初始化: home-manager switch (自动)"
          echo "验证:   scripts/verify.sh"
          echo ""
          echo "可用模型:"
          ${pkgs.lib.concatStringsSep "\n          " (map (cfg:
            ''echo "  nix run .#${cfg.name}  # ${cfg.model} (port ${toString cfg.port})"''
          ) modelConfigs)}
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        '';
      };
    };
}
