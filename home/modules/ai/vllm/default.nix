{ pkgs, lib, config, inputs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  venvPython = "${pkgs.python313}/bin/python";

  vllmLib = import ./lib.nix { inherit pkgs lib config; };

  # 导入统一配置
  vllmConfig = import ./models/config.nix;

  # 从 config.nix 读取 venv 基础目录并展开 ~
  venvBaseDir = builtins.replaceStrings ["~"] ["${config.home.homeDirectory}"] vllmConfig.venvBaseDir;

  # home.file 需要相对路径（从 config.nix 读取并去掉 ~ 前缀）
  vllmModuleRelPath = builtins.replaceStrings ["~/"] [""] vllmConfig.vllmModulePath;

  # 导入所有模型配置
  models = [
    # { cfg = import ./models/glm-4.7-flash/config.nix; }
    { cfg = import ./models/qwen3.5-35b-a3b-nvfp4/config.nix; }
    # { cfg = import ./models/qwen3-embedding-0.6b/config.nix; }
    { cfg = import ./models/qwen3-vl-embedding-2b/config.nix; }
    # { cfg = import ./models/qwen3-vl-embedding-8b/config.nix; }
    # { cfg = import ./models/qwen3.5-chat/config.nix; }
    # { cfg = import ./models/qwen3-embedding-4b/config.nix; }
    # 新增模型：在此添加一行
  ];

  aggregated = vllmLib.mkModels models;

in {
  imports = [
    ../../../../pkgs/pm2
  ];

  config = lib.mkIf isLinux {
    # Home Manager activation script - 自动初始化 uv 环境
    # 必须在 pm2 之前执行，确保 venv 存在
    home.activation.vllmSetup = lib.hm.dag.entryBefore ["initPm2"] ''
      echo "初始化 vLLM uv 环境..."

      # 创建 cache 目录
      mkdir -p "${config.home.homeDirectory}/.cache"

      # 按 venv 分组模型并创建环境
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (venvPath: models:
        let
          firstModel = builtins.head models;
          venvConfig = firstModel.venvConfig;
          pythonDeps = venvConfig.pythonDeps;
          # 默认 0.18.0 版本
          vllmVer = pythonDeps.vllm or "0.18.0";

          vllmSpec = if vllmVer == "latest" then "vllm" else "vllm==${vllmVer}";

          # 生成临时 override 文件
          overrideFile = if venvConfig.hasOverride
            then pkgs.writeText "override-${venvConfig.venvHash}.txt" venvConfig.overrideContent
            else null;

          overrideArg = if venvConfig.hasOverride
            then "--override ${overrideFile}"
            else "";
        in ''
          # 创建 venv: ${venvPath}
          if [ ! -d "${venvPath}" ]; then
            echo "创建 venv: ${venvPath} (vllm=${vllmVer}${
              lib.optionalString (pythonDeps ? torch) ", torch=${pythonDeps.torch}"
            }${
              lib.optionalString (pythonDeps ? transformers) ", transformers=${pythonDeps.transformers}"
            })"

            ${pkgs.uv}/bin/uv venv --python ${venvPython} "${venvPath}"

            source "${venvPath}/bin/activate"
            ${pkgs.uv}/bin/uv pip install \
              --index-strategy unsafe-best-match \
              --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
              --extra-index-url https://download.pytorch.org/whl/cu121 \
              ${overrideArg} \
              ${vllmSpec}
          fi
        ''
      ) (vllmLib.groupModelsByVenv venvBaseDir models))}
    '';

    # 顶层 symlink，用于 cd ~/.cache/vllm-flake && nix run .#vllm-<name> 调试
    home.file."${vllmModuleRelPath}".source = ./models;

    home.packages = aggregated.packages ++ aggregated.socatScripts;

    # pm2 服务配置 — 统一由 pm2 管理进程生命周期
    programs.pm2 = {
      enable = true;
      services = aggregated.pm2Services;
    };
  };
}
