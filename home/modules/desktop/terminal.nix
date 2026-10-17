# 终端: xfce4-terminal(XFCE 原生, VTE, 无 GL 需求)。此前选的 alacritty 在本盒不可用:
# 云 VM 无 /dev/dri/renderD128, 只有 X server 侧 IGLX 软渲染, nix 程序闭包自带的
# mesa 客户端拿不到任何 GLX fbconfig, alacritty(winit/wgpu 的 GL 硬需求)启动即
# "failed to find suitable GL configuration"; xfce4-terminal 无此依赖
{ lib, pkgs, system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  config = lib.mkIf (!isDarwin) {
    home.packages = [ pkgs.xfce.xfce4-terminal ];

    # XFCE 默认终端(右键 Open Terminal / exo-open) → xfce4-terminal
    xdg.configFile."xfce4/helpers.rc".text = ''
      TerminalEmulator=custom
      TerminalEmulatorCustom=xfce4-terminal
    '';
  };
}
