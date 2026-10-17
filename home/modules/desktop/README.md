# home/modules/desktop

clawbot 的 Linux 桌面盒（192.168.31.105，Ubuntu 24.04 + XFCE + xrdp）的桌面环境（DE）通用配置：字体、浏览器、终端、输入法、启动器。只由 `home/profiles/clawbot.nix` 引用，其余 profile 不导入；darwin 侧对应软件走 `../modules/darwin/apps/`。

## 「检测到桌面环境」的落地

flake 的 pure eval 读不到宿主机文件系统（`builtins.pathExists` 对绝对路径恒返回 `false`，`readDir`/`readFile`/`getEnv` 直接被禁），探测只能基于纯信息（`system`）。而 clawbot 的 standalone home-manager（`just switch-home clawbot`）全库唯一的 Linux 落点就是这台 XFCE + xrdp 桌面盒，故 `!isDarwin` 即等价于「检测到桌面环境则启用」。

## 组件

| 组件 | 说明 |
|---|---|
| `nerd-fonts.sauce-code-pro` + `noto-fonts-cjk-sans` + `fonts.fontconfig.enable` | 等宽字体（与 `systems/darwin.nix` 同源同款）+ CJK 字体：盒上系统 0 个中文字体，不装则中文页面/输入法候选 tofu |
| `google-chrome`（unstable + `--no-sandbox --disable-gpu`） | 盒上原本无浏览器；unstable 因为 release 旧 pin 的 dl.google.com 固定版本 `.deb` 会 404；`--no-sandbox` 因为桌面会话 root 登录（xrdp）且 nix store 的 chrome-sandbox 无法 setuid（crbug.com/638180）；`--disable-gpu` 因为云 VM 无 `/dev/dri/renderD128`、nix mesa 客户端从 server IGLX 拿不到 GLX fbconfig，默认 GPU 初始化会失败启动不了 |
| `xfce4-terminal` | 终端：XFCE 原生 VTE（无 GL 需求）。最初选的 alacritty 在本盒不可用——GLX fbconfig 拿不到（见上），alacritty 的 winit/wgpu GL 硬需求启动即挂；`xfce4/helpers.rc` 把 XFCE 默认终端（右键 Open Terminal / exo-open）指向 xfce4-terminal |
| `rofi`（unstable 2.0 裸包） | 启动器。不走 HM `programs.rofi`（stable pin 无 rofi 属性 + 2.0 配置生成兼容性未验证），裸包零生成配置；Alt+Space 经 xfconf 绑 `rofi -show drun` |
| `fcitx5` + `fcitx5-rime` + `fcitx5-configtool` | 中文输入（rime 走 rime-ice 方案）。rime 配置（`default.custom.yaml` / `rime_ice.custom.yaml` / `custom_phrase.txt`）与 darwin 侧鼠须管共用同一份 sops 密文，构建期解密部署到 `~/.local/share/fcitx5/rime`。HM 写入的 `GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS` 经 `.profile` 在 startwm.sh 阶段注入，**rime 生效须注销旧 rdp 会话重连**。fcitx5 经 XDG autostart 拉起（HM 自带的 systemd user service 依赖 graphical-session.target，在 XFCE+xrdp 下不可靠）。注意：`~/.config/fcitx5` 由 HM linkFarm 管理 → fcitx5 运行时的 UI 设置改动重启后回声明态；主 rime 数据在 `~/.local/share`（可写，`.userdb` 词库正常）。改 rime-ice 词库源后需手动删 `~/.local/share/fcitx5/rime/.rime-ice-version` 触发重部署 |
darwin 侧 clawbot（nix-darwin）不受影响：本模块整体 `mkIf (!isDarwin)` gate 关闭。

## 后续可选（未做）

- 剪贴板历史（cliphist + rofi 集成）
- rime 词库 gdrive 同步（复用 darwin 侧 `programs.linker` 的 sync 机制，目标 `~/.local/share/fcitx5/rime/sync`）
