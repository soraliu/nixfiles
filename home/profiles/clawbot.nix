{ system, lib, unstablePkgs, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = builtins.filter (el: el != "") ([
    ../core/base.nix

    ../modules/sys/fs
    ../modules/sys/network
    ../modules/sys/json
    ../modules/sys/container
    ../modules/sys/shell

    ../modules/ai/cc
    ../modules/ai/codex
    ../modules/ai/pi
    ../modules/ai/omp

    ../modules/ide/git
    ../modules/ide/zsh
    ../modules/ide/neovim
    ../modules/ide/zellij
    ../modules/ide/herdr
    ../modules/ide/search/fzf
    ../modules/ide/search/ripgrep
    ../modules/ide/copilot.nix

    ../modules/lang/nodejs.nix
    ../modules/lang/python.nix
    ../modules/lang/go.nix
    ../modules/lang/db.nix
    ../modules/lang/rust.nix

    # Paperclip pm2 service module
    # ../modules/sys/pm2/paperclip.nix

    (if isDarwin then ../modules/darwin/base.nix else "")
    (if isDarwin then ../modules/darwin/apps/rime else "")
    (if isDarwin then ../modules/darwin/apps/iterm2 else "")
  ]);

  # ---- 非 darwin(standalone home-manager, 如 Ubuntu)补齐: 字体 + 交互式 bash → zsh ----
  # 字体与 systems/darwin.nix 的 fonts.packages 保持同源同款 (unstablePkgs.nerd-fonts.sauce-code-pro);
  # darwin 由 nix-darwin 系统级管理, 此处不重复安装
  home.packages = lib.optionals (!isDarwin) [ unstablePkgs.nerd-fonts.sauce-code-pro ];
  fonts.fontconfig.enable = !isDarwin;

  # xrdp 等桌面会话的 SHELL 环境继承自 daemon(chsh 之前的 bash), 图形终端按 $SHELL 环境变量拉 shell;
  # chsh 只对之后的新登录生效. 交互式 bash 落地 profile zsh 后, home-manager 的 .zshenv 会重建
  # session vars, 因此本跳板与 sys/shell 模块 initExtra 的顺序无关.
  programs.bash.initExtra = lib.mkIf (!isDarwin) ''
    if [ -n "''${PS1:-}" ] && [ -z "''${BASH_EXECUTION_STRING:-}" ] && [ -x "''${HOME_PROFILE_DIRECTORY:-}/bin/zsh" ]; then
      exec "''${HOME_PROFILE_DIRECTORY}/bin/zsh"
    fi
  '';

  # GNOME Terminal (Ubuntu 桌面默认终端, 未显式配置 profile 字体) 跟随系统等宽字体:
  # 指到 nerd font 的 Mono 变体, p10k 图标随终端默认字体直接渲染, 无需手动选择
  dconf.settings = lib.mkIf (!isDarwin) {
    "org/gnome/desktop/interface".monospace-font-name = "SauceCodePro Nerd Font Mono 11";
  };
}
