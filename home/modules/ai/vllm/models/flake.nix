{
  description = "vLLM 多模型服务 — RTX 5090 Blackwell 优化";

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

      # 注意：flake 沙箱内使用 $HOME（shell 变量），与 lib.nix 中 config.home.homeDirectory 保持一致
      GLOBAL_VLLM_ENV = "$HOME/.cache/nix-vllm-env";

      # CUDA 运行时依赖
      runtimeLibs = with pkgs; [
        cudaPackages_12.cuda_cudart
        cudaPackages_12.libcublas
        gcc-unwrapped.lib
        stdenv.cc.cc.lib
      ];

      libPath = pkgs.lib.makeLibraryPath runtimeLibs;

      # 导入所有模型配置
      modelConfigs = [
        (import ./glm-4.7-flash/config.nix)
        (import ./qwen3.5-chat/config.nix)
        (import ./qwen3-embedding/config.nix)
      ];

      # vLLM 默认启动参数
      defaultArgs = [
        "--host 0.0.0.0"
        "--trust-remote-code"
        "--disable-log-requests"
        "--kv-cache-dtype auto"
        "--tensor-parallel-size 1"
        "--pipeline-parallel-size 1"
        "--block-size 16"
      ];

      # 为单个模型生成 flake app
      mkApp = cfg:
        let
          allArgs = defaultArgs ++ (cfg.extraArgs or []);
        in {
          type = "app";
          program = "${pkgs.writeShellScript "vllm-serve-${cfg.name}" ''
            export CUDA_VISIBLE_DEVICES=0
            export HF_HOME="$HOME/.cache/huggingface"
            export HF_ENDPOINT="https://hf-mirror.com"
            export CUDA_CACHE_PATH="$HOME/.cache/cuda"
            export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
            export CC="${pkgs.gcc}/bin/gcc"
            export CXX="${pkgs.gcc}/bin/g++"

            echo "启动 vLLM: ${cfg.name} (port ${toString cfg.port})"

            # 后台健康检查
            (
              while ! ${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString cfg.port}/health >/dev/null 2>&1; do
                sleep 2
              done
              echo "vLLM 服务已就绪 - ${cfg.name} @ http://0.0.0.0:${toString cfg.port}"
            ) &

            exec "${GLOBAL_VLLM_ENV}/bin/python" -m vllm.entrypoints.openai.api_server \
              --model ${cfg.model} \
              --port ${toString cfg.port} \
              --max-num-seqs ${toString (cfg.max-num-seqs or 256)} \
              --max-model-len ${toString cfg.max-model-len} \
              --gpu-memory-utilization ${toString cfg.gpu-memory-utilization} \
              ${pkgs.lib.concatStringsSep " \\\n              " allArgs}
          ''}";
        };

      # 生成所有模型的 apps
      modelApps = builtins.listToAttrs (map (cfg: {
        name = cfg.name;
        value = mkApp cfg;
      }) modelConfigs);

    in {
      apps.${system} = modelApps;

      devShells.${system}.default = pkgs.mkShell {
        name = "vllm-blackwell-env";

        buildInputs = with pkgs; [
          uv
          python312
          gcc
          cudaPackages_12.cuda_cudart
          cudaPackages_12.libcublas
          cudaPackages_12.cuda_nvcc
        ];

        shellHook = ''
          if [ -d "${GLOBAL_VLLM_ENV}" ]; then
            export PATH="${GLOBAL_VLLM_ENV}/bin:$PATH"
            export VIRTUAL_ENV="${GLOBAL_VLLM_ENV}"
            echo "vLLM 环境已激活: ${GLOBAL_VLLM_ENV}"
          else
            echo "vLLM 环境不存在，请先运行 home-manager switch"
          fi

          export CUDA_VISIBLE_DEVICES=0
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          echo ""
          echo "vLLM Blackwell 开发环境"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "可用模型:"
          ${pkgs.lib.concatStringsSep "\n          " (map (cfg:
            ''echo "  nix run .#${cfg.name}  # ${cfg.model} (port ${toString cfg.port})"''
          ) modelConfigs)}
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        '';
      };
    };
}
