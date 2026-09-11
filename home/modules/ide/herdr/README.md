# herdr

## 介绍

- [herdr.dev](https://herdr.dev)
- [官方文档](https://herdr.dev/docs/):[Keyboard](https://herdr.dev/docs/keyboard/) · [Configuration](https://herdr.dev/docs/configuration/) · [Config reference](https://herdr.dev/docs/config-reference/) · [CLI reference](https://herdr.dev/docs/cli-reference/)

herdr 是一个常驻后台的终端 workspace 运行时,契约如 zellij/tmux 的前缀键模型;键位配置由本 Nix 模块用 `pkgs.formats.toml` 生成 `~/.config/herdr/config.toml`,只覆盖与 zellij 概念重叠的动作键,其余沿用 herdr 默认。完整设计与实施期修订见 `docs/herdr-integration.md`。

## 安装方式

本模块从项目的 `nixpkgs-unstable` 取 `herdr`;当前 pin 的 rev 处为 **0.7.5**(仅 unstable,未进 nixos-25.11 stable)。0.7.5 默认无 `swap_pane_*` 绑定——见末段前向兼容说明。

## 键位速查(本模块覆盖项)

- 前缀:`Ctrl b`(herdr 社区默认);**前缀是单次的**,每个动作后都要重按一次。
- 在 zellij 里「按一次进模式后连按多键」的体验,改用 herdr 持久模式:
  - `prefix+g` / `Alt+g` navigate mode(连按 `h/j/k/l` 切 pane;内可输入搜索 workspace/tab)
  - `prefix+r` resize mode
  - `prefix+[` copy mode(内含 `/ ?` 搜索、`n N`、`v/Space` 选择、`y/Enter` 复制、`q/esc` 退出)

### 前缀层(对齐 zellij pane 模式)

| 动作 | 绑定 |
|---|---|
| 分屏(右/下) | `prefix+shift+l` / `prefix+shift+j`(zellij `L`/`J`) |
| 关 pane / 关 tab / detach | `prefix+q` / `prefix+x` / `prefix+d` |
| 移动焦点 | `prefix+h/j/k/l` |
| 全屏 | `prefix+z` |
| 新/上/下个/重命名 tab | `prefix+c` / `prefix+[` / `prefix+]` / `prefix+,` |
| 切 tab 1-9 | `prefix+1..9` |
| 复制/搜索 | `prefix+/`(进 copy mode 再 `/` 或 `?` 搜) |
| 编辑 scrollback | `prefix+e` |

### 直达层(无需前缀,移植 zellij `shared` 的 Alt-* )

| 动作 | 绑定 |
|---|---|
| 新 tab | `Alt t`  |
| 焦点移动 | `Alt h/j/k/l` |
| 分屏 右/下 | `Alt Right` / `Alt Down` |
| 新 worktree | `Alt n` |
| 关 pane/tab | `Alt q` / `Alt x` |
| 上/下个 tab | `Alt [` / `Alt ]` |
| 全屏 | `Alt m` |
| 切 tab 1-9 | `Alt 1..9` |
| 新 / 关 workspace | `Alt w` / `Alt d` |
| 上/下个 workspace | `Alt -` / `Alt =` |

### herdr 特有(保留默认,常用)

| 动作 | 绑定 |
|---|---|
| workspace 导航面 | `prefix+w` |
| 新 / 关 workspace | `prefix+shift+n` + `Alt+w` / `prefix+shift+d` + `Alt+d`(Alt 直达)
| 重命名 workspace | `prefix+shift+w` |
| 上/下个 workspace | `Alt -` / `Alt =`(直达;默认未绑) |
| 可搜索 workspace 导航(Session Navigator) | `prefix+g` / `Alt+g`(直达,可搜 workspace/tab) |
| 新 worktree | `prefix+shift+g` + `Alt+n`(直达) |
| 切换侧栏 | `prefix+b` |
| 设置 / 帮助 / 重载配置 | `prefix+s` / `prefix+?` / `prefix+shift+r` |
| 聚焦通知来源 | `prefix+o` |
| 上/下个 agent | `Alt+,` / `Alt+.` |

按 `prefix+?` 可随时查看当前生效的全部绑定(可 `/` 过滤)。

## 插件(Herdr Palette,`alt+p`)

- **自动安装并暴露二进制**:本模块在 `switch` 后的 activation 里做三件事(`installHerdrPalettePlugin`):
  1. **构建二进制**(`herdr plugin install ramarivera/herdr-palette --yes </dev/null`):缺才重装(重克隆 + 重建),已构建则跳过;`</dev/null` 强制非交互 stdin → `--yes` 生效,不弹 `Install this plugin? [y/N]`。
  2. **链接 cargo 子 manifest**(`herdr plugin link <plugin_root>/cargo`):覆盖 herdr 默认注册的「根 manifest」。因为根 manifest 的 pane 命令是相对路径 `target/release/herdr-palette`,而 pane 由 herdr 服务器用「服务器自己的 PATH」spawn,相对路径文件名含 `/`,PATH 搜索永远找不到 → `alt+p` 会报 `Unable to spawn target/release/herdr-palette ... No viable candidates found in PATH`。cargo 子 manifest 的 pane 命令是**裸** `herdr-palette`(靠 PATH 找)。
  3. **软链二进制到 `~/.local/bin/herdr-palette`**(`ln -sfn`):`~/.local/bin` 在交互 / 服务器 PATH 上,herdr 服务器 spawn 时才能找到 `herdr-palette`。
  - 自愈:旧坏态(根 manifest 注册、相对路径 spawn 失败)merge 后一次 `switch-darwin soraliu` 即修复 —— 2/3 步每次 switch 都刷新。
  - 需 cargo(ide profile 的 rust 模块已带)+ 联网;首次构建分钟级,之后瞬时;失败不阻断 switch;手动排查见 `home/modules/ide/herdr/default.nix` 注释。
- 装好后 `alt+p`(直达,无需前缀)打开 **Herdr Palette** —— Raycast/Linear 风模糊命令面板,可搜 workspace/tab/命令;`alt+g` 仍是 herdr 自带的可搜索 Session Navigator。

## zsh 入口

见 `home/modules/ide/zsh/{alias,fn}.zsh:`

```sh
h          # herdr
hv <dir>   # 在 cwd 建 agent 布局(左 nvim + 右上下两 shell)
hx         # herdr tab close "$HERDR_TAB_ID"
hxp        # 同上(关当前 tab)
hko        # 关停除 default/当前外的 herdr session
```

## 无法从 zellij 1:1 还原

- 浮动 pane(`ToggleFloatingPanes / EmbedOrFloating`)、标签同步(`ToggleSyncTab`):herdr 无,舍。
- `BreakPane`:改用 CLI `herdr pane move <id> --new-tab`。
- Move 模式(zellij `m`):herdr 0.7.5 无默认 swap 绑定,故暂不映射;可用 CLI `herdr pane swap --direction ...` 或日后自行补设 `swap_pane_*`。
- `ToggleTab`(zellij `Ctrl a`+`Ctrl a`):herdr 保留「双击前缀 = 发字面前缀」,`Ctrl b`+`Ctrl b`(及直达 `Ctrl b`)均被禁用,无配置项关闭;且 0.7.5 无显式「上次活跃 tab」动作。切上一个 tab 用 `prefix+[`/`alt+[`(previous_tab,by order);`alt+p` 改用于打开 Herdr Palette 插件(见下)。
- 终端态半页滚动(`Ctrl u/d`):仅 copy mode 内有;终端态用 copy mode 或鼠标。

## 通知（pi / agent 完成）

- 本模块已设 `ui.toast.delivery = "system"`:后台 workspace 的 agent(pi 等)**完成或需输入**时走 **macOS 系统通知**横幅(`terminal-notifier`,已在本模块 `home.packages` 装 — darwin only,非 darwin 跳过以免求值失败;未装时 herdr 用 osascript 兜底);`ui.sound.enabled` 默认开 → 同场景也提示音。
- 备选:`"herdr"`(in-app toast)、`"off"`(关)、`"terminal"`(让外层终端弹通知)。
- pane 边框:`ui.show_agent_labels_on_pane_borders = true`(默认 false)→ 分屏 pane 边框在无手动 pane 名时显示检测到的 agent 标签。
- pi 检测:herdr 内置 pi 屏幕检测,自动分类 idle/working/blocked/done。为更稳状态上报 + 重启后恢复原生会话,可一次性执行 `herdr integration install pi`(写 pi 配置,幂等)。
- 注意:herdr 对处于「当前聚焦 tab」的 agent抑制 toast;把 pi 放后台 tab 才会弹通知。

## 注意 / 前向兼容

- **herdr 版本**:本机走项目当前 pin 的 `nixos-unstable`(herdr **0.7.5**)。将来升级 flake input 到含 herdr ≥0.8 的 nixpkgs 时,herdr 会新增默认 `swap_pane_*=prefix+shift+h/j/k/l`,与本模块 `split_vertical=prefix+shift+l` / `split_horizontal=prefix+shift+j` **冲突**,启动会报 `config diagnostic: ... disabled keys.split_*`(分屏被废)。届时需显式重设 `swap_pane_*`、或把分屏键改回 herdr 默认(`prefix+v`/`prefix+minus`)。升级前先核对。
- **`hv` 重建布局**:依赖 `herdr tab create` / `pane split` 的 JSON 字段(`.result.root_pane.pane_id`、`.result.pane.pane_id`)与 `--ratio` 语义;首次用前先跑 `herdr tab create --cwd /tmp --label tmp` 观察真实 JSON,必要时微调 `fn.zsh` 里的 `jq` 路径。
