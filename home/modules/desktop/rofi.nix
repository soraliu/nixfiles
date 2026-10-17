# 启动器: rofi(unstable 2.0)。不走 HM programs.rofi —— stable pin 已无 rofi 属性,
# 而 2.0 大版本的 HM 配置生成兼容性未验证; 裸包 + 零生成配置 = 零风险, rofi -show drun
# 开箱即用, 想定制再手写 ~/.config/rofi/config.rasi
{ lib, unstablePkgs, pkgs, system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  config = lib.mkIf (!isDarwin) {
    home.packages = [ unstablePkgs.rofi ];

    # XFCE 快捷键 Alt+Space → rofi drun。写入 xfconf; 无 session bus(headless 激活)
    # 时起临时 dbus(与旧 gnomeTerminalGnomeDark 同款兜底)
    home.activation.rofiXfceHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      declare -a _wrap=()
      if ! [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
        _wrap+=("${pkgs.dbus}/bin/dbus-run-session" "--")
      fi
      _xq="${pkgs.xfce.xfconf}/bin/xfconf-query"
      if "''${_wrap[@]}" "$_xq" -c xfce4-keyboard-shortcuts -p '/commands/custom/<Alt>space' \
           -n -t string -s "rofi -show drun" 2>/dev/null; then
        :
      else
        "''${_wrap[@]}" "$_xq" -c xfce4-keyboard-shortcuts -p '/commands/custom/<Alt>space' \
             -s "rofi -show drun" || true
      fi
    '';
  };
}
