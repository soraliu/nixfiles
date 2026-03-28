{
  description = "vLLM 多模型服务 — RTX 5090 Blackwell 优化";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/cfa1f3da48ac9533e0114e90f20c0219612672a7";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # CUDA 运行时依赖 (使用 cudaPackages_13_2 匹配 WSL CUDA 13.2)
      runtimeLibs = with pkgs; [
        cudaPackages_13_2.cuda_cudart
        cudaPackages_13_2.libcublas
        gcc-unwrapped.lib
        stdenv.cc.cc.lib
      ];

      libPath = pkgs.lib.makeLibraryPath runtimeLibs;

      # 导入所有模型配置
      modelConfigs = [
        (import ./glm-4.7-flash/config.nix)
        # (import ./qwen3.5-chat/config.nix)
        # (import ./qwen3-embedding-4b/config.nix)
      ];

      # vLLM 默认启动参数
      # 注意：CPU 后端不支持 FP8 KV cache（vLLM 会自动启用 chunked prefill + prefix caching，与 FP8 不兼容）
      # GPU 用户可以在模型 config 中通过 extraArgs 覆盖 kv-cache-dtype
      defaultArgs = [
        "--host 0.0.0.0"
        "--trust-remote-code"
        "--tensor-parallel-size 1"
        "--pipeline-parallel-size 1"
        "--block-size 16"
        "--disable-frontend-multiprocessing"
        "--enforce-eager"
      ];

      # 使用带有 vllm 的 Python 环境
      # pythonModule 是构建机制，不是运行时环境；需要用 withPackages 创建可运行的环境
      vllmPython = pkgs.python3.withPackages (ps: [ ps.vllm ]);

      # 通过 nix run 启动 vllm 的包装脚本
      mkVllmRunner = cfg:
        let
          allArgs = defaultArgs ++ (cfg.extraArgs or []);
        in pkgs.writeShellScript "vllm-run-${cfg.name}" ''
          export CUDA_VISIBLE_DEVICES=0
          export CUDA_MODULE_LOADING=LAZY
          export HF_HOME="$HOME/.cache/huggingface"
          export HF_ENDPOINT="https://hf-mirror.com"
          export CUDA_CACHE_PATH="$HOME/.cache/cuda"
          export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${libPath}:$LD_LIBRARY_PATH"
          export LD_PRELOAD="/usr/lib/wsl/lib/libcuda.so"
          export PATH="/usr/lib/wsl/lib:/usr/bin:$PATH"
          export CC="${pkgs.gcc}/bin/gcc"
          export CXX="${pkgs.gcc}/bin/g++"

          # 禁用 inductor autotune，大幅减少启动时间
          export VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE=0
          export VLLM_ENABLE_INDUCTOR_COORDINATE_DESCENT_TUNING=0

          # RTX 5090 Blackwell 稳定性优化
          if [ -n "$(which nvcc 2>/dev/null)" ]; then
            export TRITON_PTXAS_PATH="$(dirname $(which nvcc))/ptxas"
          fi

          echo "启动 vLLM: ${cfg.name} (port ${toString cfg.port})"

          # 后台健康检查
          (
            while ! ${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString cfg.port}/health >/dev/null 2>&1; do
              sleep 2
            done
            echo "vLLM 服务已就绪 - ${cfg.name} @ http://0.0.0.0:${toString cfg.port}"
          ) &

          # 使用 nix 的 python 环境运行 vllm（vllmPython 已经包含 vllm 模块）
          exec ${vllmPython}/bin/python -m vllm.entrypoints.openai.api_server \
            --model ${cfg.model} \
            --port ${toString cfg.port} \
            --max-num-seqs ${toString (cfg.max-num-seqs or 256)} \
            --max-model-len ${toString cfg.max-model-len} \
            --gpu-memory-utilization ${toString cfg.gpu-memory-utilization} \
            ${pkgs.lib.concatStringsSep " \\\n              " allArgs}
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

      # nix run 使用的包
      packages.${system} = {
        vllm-run-glm4-flash = mkVllmRunner (builtins.head modelConfigs);
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "vllm-blackwell-env";

        buildInputs = with pkgs; [
          python3
          gcc
          cudaPackages_12.cuda_cudart
          cudaPackages_12.libcublas
          cudaPackages_12.cuda_nvcc
        ];

        shellHook = ''
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
