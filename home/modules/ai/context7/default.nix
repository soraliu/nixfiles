{ config, lib, ... }: {
  # ctx7 CLI — 通过 npm 全局安装，提供 context7 skills 能力（替代 MCP 模式）
  # 依赖 volta/node 已在 nodejs.nix 中安装
  config.home.activation.initContext7 = lib.hm.dag.entryAfter [ "initVolta" ] ''
    export PATH="$HOME/.volta/bin:$PATH"
    # 仅在 ctx7 未安装时才执行安装
    if ! command -v ctx7 &>/dev/null; then
      echo "Installing ctx7 CLI..."
      npm install -g ctx7
    fi
  '';
}
