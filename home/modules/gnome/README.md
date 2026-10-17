# home/modules/gnome

clawbot Linux 宿主机（xrdp 桌面盒，当前为 192.168.31.105 / Ubuntu 24.04 + XFCE + gnome-terminal）的桌面/GNOME 相关软件安装。只由 `home/profiles/clawbot.nix` 引用，其余 profile 不导入。

## 「检测到桌面环境」的落地

- flake 的 pure eval 读不到宿主机文件系统：`builtins.pathExists` 对绝对路径恒返回 `false`（静默），`builtins.readDir`/`builtins.readFile` 直接报 `forbidden in pure evaluation mode`，`getEnv` 同样被禁。eval 期探测宿主机 fs 不可行，判别只能基于纯信息（`system`）。
- clawbot 的 standalone home-manager（`just switch-home clawbot`）全库唯一的 Linux 落点就是这台桌面盒：`!isDarwin` 等价于「检测到桌面环境则默认安装」，且与 `clawbot.nix` 内其它 `!isDarwin` gate（字体、zsh 跳板、gnome-terminal 配色）风格一致。
- darwin 侧 clawbot（nix-darwin）不装：Chrome 走 `bin/darwin/post-install-pkgs` 的 dmg 安装，不经 home-manager，避免双份。

## 装了什么

| 包 | 说明 |
|---|---|
| `unstablePkgs.google-chrome`（override `commandLineArgs = "--no-sandbox"`） | 盒上原本一个浏览器都没有（无 firefox / chromium / snap）—— 这是「浏览器打不开」的根因。走 unstable pin：google-chrome 的 src 是 dl.google.com 固定版本 `.deb`，release 分支旧 pin 的 URL 会 404。`--no-sandbox` 必要性：桌面会话以 root 登录（xrdp/lightdm），Chrome 以 root 运行时内核 sandbox 不可用，nix store 里的 `chrome-sandbox` 也无法 setuid（<https://crbug.com/638180>） |
| `unstablePkgs.noto-fonts-cjk-sans` | 盒上 `fc-list` 无任何 CJK 字体，不装则中文页面 tofu；`clawbot.nix` 已开 `fonts.fontconfig.enable`，该字体随 profile 自动进 fontconfig |

run 时用户无需记忆参数：`--no-sandbox` 由 nixpkgs google-chrome 的上游 `commandLineArgs` 参数注入 wrapper，终端直接 `google-chrome` 启动。

## 增补桌面软件

新的桌面/GNOME 软件往 `default.nix` 的 `home.packages` 里加，仍受 `!isDarwin` gate 保护；darwin 专用软件续走 `../modules/darwin/apps/`。
