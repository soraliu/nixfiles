# 终端: 替换 gnome-terminal(去 GNOME/dconf 依赖), 配色/字体继承原 GNOME dark 方案
{ lib, unstablePkgs, system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  config = lib.mkIf (!isDarwin) {
    programs.alacritty = {
      enable = true;
      package = unstablePkgs.alacritty;
      settings = {
        env.TERM = "xterm-256color";
        window.padding = { x = 4; y = 4; };
        font = {
          normal.family = "SauceCodePro Nerd Font Mono";
          size = 11.0;
        };
        colors.primary = {
          background = "#171421";
          foreground = "#d0cfcc";
        };
      };
    };

    # XFCE 默认终端(右键 Open Terminal / exo-open) → alacritty
    xdg.configFile."xfce4/helpers.rc".text = ''
      TerminalEmulator=custom
      TerminalEmulatorCustom=alacritty
    '';
  };
}
