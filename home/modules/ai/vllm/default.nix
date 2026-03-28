{ pkgs, lib, config, inputs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  venvPython = "${pkgs.python313}/bin/python";

  vllmLib = import ./lib.nix { inherit pkgs lib config; };

  # 导入统一配置
  vllmConfig = import ./models/config.nix;

  # 从 config.nix 读取 venv 路径并展开 ~
  venvPath = builtins.replaceStrings ["~"] ["${config.home.homeDirectory}"] vllmConfig.venvPath;

  # home.file 需要相对路径（从 config.nix 读取并去掉 ~ 前缀）
  vllmModuleRelPath = builtins.replaceStrings ["~/"] [""] vllmConfig.vllmModulePath;

  # 导入所有模型配置
  models = [
    # { cfg = import ./models/glm-4.7-flash/config.nix; }
    # { cfg = import ./models/qwen3-vl-embedding-2b/config.nix; }
    { cfg = import ./models/qwen3-vl-embedding-8b/config.nix; }
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
    home.activation.vllmSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "初始化 vLLM uv 环境..."

      # 创建 cache 目录
      mkdir -p "${config.home.homeDirectory}/.cache"

      # 清理损坏的环境
      if [ -d "${venvPath}" ]; then
        if [ ! -f "${venvPath}/bin/activate" ]; then
          echo "清理损坏的虚拟环境..."
          rm -rf "${venvPath}"
        elif [ -x "${venvPath}/bin/python" ] && ! "${venvPath}/bin/python" -c 'import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 13) else 1)'; then
          echo "清理不兼容的虚拟环境（需要 Python 3.13）..."
          rm -rf "${venvPath}"
        fi
      fi

      # 创建虚拟环境
      if [ ! -d "${venvPath}" ]; then
        echo "创建 uv 虚拟环境: ${venvPath}"
        ${pkgs.uv}/bin/uv venv --python ${venvPython} "${venvPath}"
      fi

      # 安装依赖（使用 override 文件覆盖 transformers 版本）
      echo "安装 vLLM 依赖..."
      source "${venvPath}/bin/activate"
      ${pkgs.uv}/bin/uv pip install \
        --index-strategy unsafe-best-match \
        --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
        --extra-index-url https://download.pytorch.org/whl/cu121 \
        --override ${./models/overrides.txt} \
        vllm==0.18.0 \
        "torch==2.10.0" \
        --no-cache-dir
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
