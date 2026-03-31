{
  description = "vLLM 多模型服务 — RTX 5090 + buildFHSEnv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    cuda = pkgs.cudaPackages_12_8;

    # 引用共享工具函数（不重复代码）
    vllmLib = import ./lib.nix { inherit pkgs; lib = pkgs.lib; };
    vllmConfig = vllmLib.vllmConfig;

    # CUDA 库路径, makeLibraryPath 会自动添加 /lib 后缀
    libPath = pkgs.lib.makeLibraryPath [
      cuda.cuda_cudart
      cuda.libcublas
      # pkgs.gcc13.cc
      pkgs.gcc13.cc.lib
      #pkgs.zlib
      pkgs.glibc
      pkgs.glibc.dev
    ];

    # 导入所有模型配置
    modelConfigs = [
      (import ./glm-4.7-flash/config.nix)
      (import ./qwen3.5-35b-a3b-nvfp4/config.nix)
      (import ./qwen3-vl-8b-instruct/config.nix)
      (import ./qwen3-embedding-0.6b/config.nix)
      (import ./qwen3-vl-embedding-2b/config.nix)
      (import ./qwen3-vl-embedding-8b/config.nix)
      (import ./qwen3-reranker-0.6b/config.nix)
    ];

    # vLLM 默认启动参数
    defaultArgs = [
      "--host 0.0.0.0"
      "--trust-remote-code"
      "--tensor-parallel-size 1"
      "--pipeline-parallel-size 1"
    ];

    # ========== buildFHSEnv ==========
    fhsEnv = pkgs.buildFHSEnv {
      name = "vllm-nvfp4";
      targetPkgs = pkgs: [
        pkgs.python312
        pkgs.python312Packages.pip
        pkgs.uv
        pkgs.git
        pkgs.zlib
        pkgs.ncurses5
        pkgs.gcc13.cc
        pkgs.gcc13.cc.lib

        # CUDA 12.8 工具链
        cuda.cudatoolkit
        cuda.cuda_cudart
        cuda.cuda_nvcc
        cuda.cudnn
        cuda.libcublas
        cuda.libcusparse
        cuda.libcurand
        cuda.nccl
        cuda.cuda_nvrtc
      ];

      profile = ''
        export LD_LIBRARY_PATH=/usr/lib/wsl/lib:''${LD_LIBRARY_PATH:-}
        export LD_LIBRARY_PATH=${pkgs.gcc13.cc.lib}/lib:''${LD_LIBRARY_PATH:-}
        export CUDA_HOME=${cuda.cudatoolkit}
        export PATH=${cuda.cuda_nvcc}/bin:''${PATH:-}
      '';

      runScript = "bash";
    };

    # ========== 为每个模型创建启动脚本(不使用 FHS 环境) ==========
    mkModelRunner = cfg:
      let
        pythonDeps = cfg.pythonDeps or {};
        venvHash = vllmLib.mkVenvHash pythonDeps;
        venvPath = "$HOME/.cache/vllm-venv-${venvHash}";
        allArgs = defaultArgs ++ (cfg.extraArgs or []);

        extraEnv = cfg.extraEnv or {};
        extraEnvExports = pkgs.lib.concatStringsSep "\n"
          (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") extraEnv);
      in pkgs.writeShellScriptBin cfg.name ''
        set -euo pipefail

        VENV_PATH="${venvPath}"

        if [ ! -d "$VENV_PATH" ]; then
          echo "错误: venv 不存在: $VENV_PATH"
          echo "请运行: home-manager switch"
          exit 1
        fi

        source "$VENV_PATH/bin/activate"

        export HF_HOME="$HOME/.cache/huggingface"
        export HF_ENDPOINT="https://hf-mirror.com"
        export CUDA_VISIBLE_DEVICES=0
        export CUDA_HOME="${cuda.cudatoolkit}"
        export CC="${pkgs.gcc13.cc}/bin/gcc"
        export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.gcc13.cc.lib}/lib:''${LD_LIBRARY_PATH:-}"
        export PATH="/usr/lib/wsl/lib:/usr/bin:$PATH"

        # vLLM 优化
        # 使用默认的启发式规则快速编译即可，不去穷举微调, 牺牲 1% 性能
        export VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE=0
        export VLLM_ENABLE_INDUCTOR_COORDINATE_DESCENT_TUNING=0

        ${extraEnvExports}

        echo "启动 vLLM: ${cfg.name} (port ${toString cfg.port})"

        exec python -m vllm.entrypoints.openai.api_server \
          --model ${cfg.model} \
          --port ${toString cfg.port} \
          --max-num-seqs ${toString (cfg.max-num-seqs or 256)} \
          --max-model-len ${toString cfg.max-model-len} \
          --gpu-memory-utilization ${toString cfg.gpu-memory-utilization} \
          ${pkgs.lib.concatStringsSep " \\\n          " allArgs}
      '';

    # ========== 生成 apps ==========
    modelApps = builtins.listToAttrs (map (cfg: {
      name = cfg.name;
      value = {
        type = "app";
        program = "${mkModelRunner cfg}/bin/${cfg.name}";
      };
    }) modelConfigs);

  in {
    apps.${system} = modelApps;

    # nix develop 进入 FHS 环境
    devShells.${system}.default = fhsEnv.env;
  };
}
