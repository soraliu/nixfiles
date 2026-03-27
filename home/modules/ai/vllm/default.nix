{ pkgs, lib, config, ... }:

let
  isLinux = pkgs.stdenv.isLinux;

  vllmLib = import ./lib.nix { inherit pkgs lib config; };

  # 顶层 symlink，用于 nix run 调试入口
  vllmModulePath = "${config.home.homeDirectory}/.cache/vllm-flake";

  # 通用 vllm CLI wrapper（不绑定特定模型）
  vllmWrapper = pkgs.writeShellScriptBin "vllm" ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${vllmLib.libPath}:$LD_LIBRARY_PATH"
    exec "${vllmLib.GLOBAL_VLLM_ENV}/bin/vllm" "$@"
  '';

  # 导入所有模型配置
  models = [
    # { cfg = import ./models/glm-4.7-flash/config.nix; }
    { cfg = import ./models/qwen3.5-chat/config.nix; }
    { cfg = import ./models/qwen3-embedding/config.nix; }
    # 新增模型：在此添加一行
  ];

  aggregated = vllmLib.mkModels models;

in {
  config = lib.mkIf isLinux {
    # 顶层 symlink，用于 cd ~/.cache/vllm-flake && nix run .#vllm-<name> 调试
    home.file."${vllmModulePath}".source = ./.;

    home.packages = aggregated.packages ++ aggregated.wrappers ++ aggregated.serveScripts ++ aggregated.socatScripts ++ [
      vllmWrapper
    ];

    # systemd user services — autostart 由各模型 config.nix 中的 autostart 字段控制
    systemd.user.services = aggregated.systemdServices;

    # 初始化共享 vLLM Python 环境
    home.activation.initVllm = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      VLLM_ENV="${vllmLib.GLOBAL_VLLM_ENV}"
      PYTHON="$VLLM_ENV/bin/python"
      EXPECTED_PYTHON_VERSION="3.12"

      if [ -x "$PYTHON" ]; then
        CURRENT_PYTHON_VERSION="$($PYTHON -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
        if [ "$CURRENT_PYTHON_VERSION" != "$EXPECTED_PYTHON_VERSION" ]; then
          echo "Recreating vLLM environment at $VLLM_ENV with Python ${pkgs.python312.version}..."
          rm -rf "$VLLM_ENV"
        fi
      fi

      if [ ! -x "$PYTHON" ]; then
        echo "Creating vLLM environment at $VLLM_ENV..."
        ${pkgs.uv}/bin/uv venv --python ${pkgs.python312}/bin/python "$VLLM_ENV"
      fi

      if ! "$PYTHON" -c "import vllm" >/dev/null 2>&1; then
        echo "Installing vLLM..."
        ${pkgs.uv}/bin/uv pip install --python "$PYTHON" --upgrade vllm
      fi

      mkdir -p "${config.home.homeDirectory}/.cache/cuda"
    '';
  };
}
