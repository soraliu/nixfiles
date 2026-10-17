# 桌面环境(DE)通用软件安装: 由 ../profiles/clawbot.nix 引用, 非 darwin(即 clawbot 的
# Linux 桌面盒)生效, 详见同目录 README.md
{ lib, unstablePkgs, system, ... }:

let
  # 「检测到桌面环境」的落地: flake pure eval 读不到宿主机 fs(builtins.pathExists
  # 绝对路径恒 false), 而 clawbot 的 standalone home-manager 唯一 Linux 落点就是这台
  # XFCE + xrdp 桌面盒; darwin 侧对应软件走 ../modules/darwin/apps
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = [ ./default-apps.nix ./fcitx5-rime.nix ./rofi.nix ];

  config = lib.mkIf (!isDarwin) {
    home.packages = [
      # 等宽字体, 与 systems/darwin.nix fonts.packages 同源同款
      unstablePkgs.nerd-fonts.sauce-code-pro
      # CJK: 盒上系统 0 个中文字体, 不装则中文页面/输入法候选 tofu
      unstablePkgs.noto-fonts-cjk-sans
      # 浏览器(盒上原本一个都没有, 即"浏览器打不开"根因); 走 unstable 因为 google-chrome
      # 的 src 是 dl.google.com 固定版本 .deb, release 旧 pin 会 404; --no-sandbox 因为
      # 桌面会话 root 登录(xrdp) + nix store chrome-sandbox 无法 setuid(crbug.com/638180);
      # --disable-gpu 因为云 VM 无 /dev/dri/renderD128, nix mesa 客户端从 server IGLX
      # 拿不到 GLX fbconfig, 默认 GPU 初始化失败 chrome 起不来, xrdp 下软渲染反正无加速
      (unstablePkgs.google-chrome.override {
        commandLineArgs = "--no-sandbox --disable-gpu";
      })
    ];
    fonts.fontconfig.enable = true;

    # 非 NixOS 上的归一化(XDG 目录/GTK module path 等), HM 官方 genericLinux target
    targets.genericLinux.enable = true;
  };
}
