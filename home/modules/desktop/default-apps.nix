# 默认应用集成: 终端(xfce4-terminal) + 浏览器注册 + XDG mime 关联。XFCE 的 exo 链
# (helpers.rc) 与 XDG 标准(xdg.mimeApps + xdg-utils) 双轨声明, 治「nix GUI 应用装了
# 但桌面注册缺位」类问题(曾因 WebBrowser 未注册, 点菜单浏览器报错)
{ lib, pkgs, system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  config = lib.mkIf (!isDarwin) {
    home.packages = [
      # XFCE 原生 VTE 终端(无 GL 需求; alacritty 的 GL 硬需求在无 /dev/dri 的
      # xrdp 环境不可用, 见同目录 README)
      pkgs.xfce.xfce4-terminal
      # xdg-open / xdg-mime: 盒上原本不装, 点链接/文件缺标准派发链
      pkgs.xdg-utils
    ];

    # XFCE helpers (菜单/右键 exo-open --launch ...): 终端与浏览器
    xdg.configFile."xfce4/helpers.rc".text = ''
      TerminalEmulator=custom
      TerminalEmulatorCustom=xfce4-terminal
      WebBrowser=custom
      WebBrowserCustom=google-chrome
    '';

    # XDG 标准关注册: 点 http(s)/html 与文件管理器目录的默认应用
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "text/html" = "google-chrome.desktop";
        "inode/directory" = "thunar.desktop";
      };
    };
  };
}
