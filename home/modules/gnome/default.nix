# clawbot Linux 宿主机(xrdp 桌面盒)的桌面/GNOME 相关软件安装, 由 ../profiles/clawbot.nix 引用
# 详见同目录 README.md
{ lib, unstablePkgs, system, ... }:

let
  # 「检测到 gnome/桌面环境则默认安装」的落地: gate = !isDarwin —— flake 的 pure eval
  # 读不到宿主机文件系统(builtins.pathExists 绝对路径恒 false, readDir 直接报错), 探测
  # 只能基于纯平台信息; 而 clawbot 的 standalone home-manager 只落在这台桌面盒上,
  # 非 darwin 即等价于「检测到桌面环境」。darwin 侧 Chrome 走 bin/darwin post-install
  # 的 dmg 安装, 不经本模块, 避免双份。
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  home.packages = lib.optionals (!isDarwin) [
    # 根因: 盒上原本没有任何浏览器(无 firefox/chromium/snap) 「浏览器打不开」。
    # 走 unstable: google-chrome 的 src 是 dl.google.com 固定版本 .deb, release 旧 pin
    # 的版本 URL 会 404, 浏览器必须跟 unstable 拿新构建。
    # --no-sandbox: 桌面会话以 root 登录(xrdp/lightdm), Chrome 以 root 运行时内核
    # sandbox 不可用, nix store 里的 chrome-sandbox 也无法 setuid (crbug.com/638180),
    # 故经上游 commandLineArgs 参数注入。
    (unstablePkgs.google-chrome.override {
      commandLineArgs = "--no-sandbox";
    })

    # 盒上 fc-list 无任何 CJK 字体, 不装则中文页面全是 tofu; clawbot.nix 已开
    # fonts.fontconfig.enable, 本字体随 home.packages 自动进 fontconfig
    unstablePkgs.noto-fonts-cjk-sans
  ];
}
