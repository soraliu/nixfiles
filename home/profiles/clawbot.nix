{ system, pkgs, lib, unstablePkgs, ... }:

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

    # 桌面环境(DE)通用软件: 字体/浏览器/终端/输入法/启动器
    ../modules/desktop

    # Paperclip pm2 service module
    # ../modules/sys/pm2/paperclip.nix

    (if isDarwin then ../modules/darwin/base.nix else "")
    (if isDarwin then ../modules/darwin/apps/rime else "")
    (if isDarwin then ../modules/darwin/apps/iterm2 else "")
  ]);

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

  # 配色不跟随系统/主题, 固定为内置 "GNOME dark" 方案: 色值取自 gnome-terminal 3.52.0
  # (Ubuntu 24.04 实装版本) 的内置定义, 等价于 GUI 手选 Built-in schemes: GNOME dark
  # (palette 即该版本默认 GNOME palette, 保持不动).
  # dconf 的 profile 按 UUID 寻址且无通配/间接层, 声明式的 dconf.settings 写不了"当前
  # default profile", 故在 activation 时动态解析机器当前的 default 再写键 —— 不写死出厂
  # UUID, 换机器或手动改过 default 均无需改配置.
  # 写入走 dconf CLI 而非 gsettings set: nixpkgs glib 未提供 dconf backend 插件,
  # gsettings set 会静默落 memory backend (rc=0 却不写库); dconf CLI 直连 dconf-service,
  # 与 home-manager 自身 dconfSettings 段同一通路.
  # 注意: 与 dconf.settings 不同, 此段不参与 hm 卸载 cleanup, 丢弃配色时需手动 reset 三键.
  home.activation.gnomeTerminalGnomeDark = lib.mkIf (!isDarwin)
    (lib.hm.dag.entryAfter [ "dconfSettings" ] ''
      _gs="${pkgs.glib}/bin/gsettings"
      _dc="${pkgs.dconf}/bin/dconf"
      _base=/org/gnome/terminal/legacy/profiles:
      # 无 session bus (headless 激活) 时起临时 bus; dconf CLI 依赖 session dbus
      declare -a _wrap=()
      if ! [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
        _wrap+=("${pkgs.dbus}/bin/dbus-run-session" "--")
      fi
      # 解析 default profile: 先读 dconf 显式值, 没有再取 gschema 默认 (gsettings get).
      # 未装 gnome-terminal (无 schema) 的机器上两者皆空, 静默跳过.
      _profile="$("''${_wrap[@]}" "$_dc" read "''${_base}/default" 2>/dev/null || true)"
      if [ -z "$_profile" ]; then
        _profile="$("''${_wrap[@]}" "$_gs" get org.gnome.Terminal.ProfilesList default 2>/dev/null || true)"
      fi
      _profile="''${_profile//\'/}" # 两者输出都带单引号
      if [ -n "$_profile" ]; then
        _p="''${_base}/:''${_profile}/"
        "''${_wrap[@]}" "$_dc" write "''${_p}use-theme-colors" false
        "''${_wrap[@]}" "$_dc" write "''${_p}foreground-color" "'#d0cfcc'"
        "''${_wrap[@]}" "$_dc" write "''${_p}background-color" "'#171421'"
      fi
    '');
}
