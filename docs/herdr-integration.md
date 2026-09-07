# 集成 herdr 并将 zellij 配置转换成 herdr 配置

## Context（背景与目标）

当前仓库用 Home-Manager 模块管理 zellij(`home/modules/ide/zellij/`):基于 KDL 的 `Ctrl a` 持久 "pane" 模式键位 + `shared` 块大量 `Alt-*` 直达快捷键 + 自定义 zjstatus 状态栏 + 4 套布局与 zsh 别名 `z/zx/zxp/zko/zl/zv` 和函数 `zellij-layout-{coding,agent}`。

目标:集成 [herdrdev/herdr](https://github.com/herdrdev/herdr),把上述体验迁移到 herdr —— 像用 zellij 快捷键一样用 herdr;对 herdr 特有功能(workspace/agent/worktree/通知...)沿用现有键位设计原则(prefix=`ctrl+b`(herdr 社区默认)、vim 风 `h/j/k/l`、Alt 直达和弦)扩展。

### 关键事实(已核实)
- herdr 在 nixpkgs:`pkgs/by-name/he/herdr/package.nix`,`0.8.2`,`platforms.unix`,**仅 `nixos-unstable`,未进 `nixos-25.11`**——和现有 zellij 一样必从 `unstablePkgs` 引入。
- herdr 配置:`~/.config/herdr/config.toml`(TOML);`herdr --default-config` 打印默认。
- **核心模型差异(最重要)**:herdr《Concepts》明确只有 3 种 mode —— terminal / **prefix(只等下一动作即退,非 zellij 持久 pane 模式)** / **navigate(prefix+g,持久,可连按 h/j/k/l 切 pane)**;另 resize mode(`prefix+r`)、copy mode(`prefix+[`)亦持久。⇒ zellij「按一次 Ctrl a 后连按多键」无法 1:1 还原,缓解:① herdr 直达和弦 平移 zellij `shared` 的 Alt 键;② 持久导航/调整依靠 herdr 持久模式(prefix+g / prefix+r / prefix+[)。
- herdr 无浮动 pane、标签同步(`ToggleSyncTab`)、`BreakPane`(可 `herdr pane move --new-tab` 补脚本)、终端态半页滚动;无 KDL 布局文件(用 CLI `tab create`+`pane split`+`pane run` 重建)。
- `HOME_PROFILE_DIRECTORY`(自定义 nvim 路径)已由 `home/modules/home-manager/default.nix` 定义;`jq`/`gojq` 已由 `home/modules/sys/json/default.nix` 进 profile → `zv→hv` 重建拆屏可放心用 jq。

## Decisions（已与用户敲定）

| 项 | 决定 |
|---|---|
| Q1 安装策略 | **并存**:zellij 与 herdr 两个 HM 模块都装载(`~/.config/zellij` 与 `~/.config/herdr` 并存,互不冲突) |
| Q2 前缀 | **用 herdr 默认 `ctrl+b`**(与社区默认一致;前缀键本身不对齐 zellij 的 Ctrl a,前缀后的动作键仍对齐 zellij) |
| Q3 直达层 | **照搬** zellij `shared` 的 `Alt-*` 和弦到 herdr 直达绑定(主终端已实测可用) |
| Q4 布局 | **完整重建** agent 布局;**去掉** `zl`(coding)与 `zlx`;`zv`→`hv`(herdr);其余 `z*` 动作别名转 `h*` |
| Q5 外观 | **完全用 herdr 默认外观**(主题/catppuccin、底栏、侧栏都默认,不设 `[theme]`/`[ui]`),用户后续自行调整 |
| Q6 herdr 特有键位 | **保留 herdr 默认**,仅在「zellij/herdr 概念重叠」处覆盖键位其余留给用户自行修改 |

> 别名微调(本次提交将如此处理,review 时一句话即可推翻):
> 保留 `z='zellij'`(并存启动器),新增 `h='herdr'`;移除 zellij 的 `zx/zxp/zko/zl/zv` 动作别名,改为 herdr 的 `hx/hxp/hko/hv`(`hl`/`zlx` 不保留)。即 zellij 仅剩 `z` 启动器可用,日常动作迁到 `h*`。若你希望连 `z` 也改 `h`(zellij 仅按 `zellij` 字面启动),review 时告知即可。

## Approach

新建 HM 模块 `home/modules/ide/herdr`(镜像 zellij 模块骨架),用 `pkgs.formats.toml` 生成类型安全的 `config.toml`(只含 `[keys]` 覆盖,其余 herdr 默认)。键位两层映射:前缀层(zellij pane-mode 单动 → `prefix+key`,前缀=`ctrl+b`)+ 直达层(zellij `shared` 的 Alt 键作 herdr 数组绑定)+ herdr 特有保留默认。持久导航/调整引导 herdr 持久模式(navigate/resize/copy)。zsh 别名/函数按 Decision 迁移(`zv`→`hv` 用 CLI+jq 重建,nvim 取 `$HOME_PROFILE_DIRECTORY/bin/nvim`,需 HERDR_TAB_ID/session 环境变量)。

## 建议的 herdr `[keys]`(仅列覆盖项,其余默认)

```toml
[keys]
prefix = "ctrl+b"
# zellij/herdr 重叠处覆盖(单次前缀,每次重按 Ctrl b)
detach            = "prefix+d"                              # zellij d(把 herdr 默认 prefix+q 让给 close_pane)
close_pane        = "prefix+q"                              # zellij q CloseFocus
close_tab         = "prefix+x"                              # zellij x CloseTab
new_tab           = ["prefix+c", "alt+t"]                   # +zellij Alt t
previous_tab      = ["prefix+[", "alt+["]                   # zellij [ / Alt [
next_tab          = ["prefix+]", "alt+]"]                   # zellij ] / Alt ]
rename_tab        = "prefix+comma"                          # zellij ,
# switch_tab      默认 "prefix+1..9" 不动;Alt 1..9 经 [keys.indexed] 叠加
focus_pane_left   = ["prefix+h", "alt+h"]                   # zellij h / Alt h
focus_pane_down   = ["prefix+j", "alt+j"]
focus_pane_up     = ["prefix+k", "alt+k"]
focus_pane_right  = ["prefix+l", "alt+l"]
split_vertical   = ["prefix+L", "alt+right"]                # zellij L / Alt Right(并排)
split_horizontal = ["prefix+J", "alt+down", "alt+n"]        # zellij J / Alt Down / Alt n(堆叠)
zoom             = ["prefix+z", "alt+m"]                    # zellij z / Alt m
copy_mode        = ["prefix+[", "prefix+/"]                 # zellij /(进 copy mode 再 / 搜)
# resize_mode     默认 prefix+r 与 zellij 一致;进去后 h/j/k/l 持久调整
# edit_scrollback 默认 prefix+e 与 zellij 一致

# 以下 zellij 概念 herdr 无对应,取舍见下「无法还原」:
#   w 浮动 pane / s 同步 tab / b BreakPane / m 移动模式 / Ctrl a ToggleTab / Ctrl u-d 半页滚动

[keys.indexed]
tabs = "alt"                                               # → Alt+1..9 切标签(zellij Alt 1-9)
```

> rename_pane:**保留 herdr 默认 `prefix+shift+p`**,不尝试 zellij `prefix+;`(分号键名支持不确定;遵循 Q6 保留默认)。zellij `;`≈herdr `prefix+shift+p`。
> 终端态 `prefix+[`/`prefix+]`/`prefix+'['` 等:`[`/`]` 是否被 herdr 接受,实施时用 `herdr --default-config`/启动日志核对;若不接受再回退方案(形如 `prefix+bracketleft`)。

### 直达层对照(zellij `shared` → herdr 数组)

| action | 绑定 | zellij |
|---|---|---|
| new_tab | prefix+c, alt+t | Alt t |
| split_vertical | prefix+L, alt+right | L, Alt Right |
| split_horizontal | prefix+J, alt+down, alt+n | J, Alt Down, Alt n |
| focus_pane_* | prefix+*, alt+h/j/k/l | h/j/k/l, Alt h/j/k/l |
| close_pane | prefix+q, alt+q | q, Alt q |
| close_tab | prefix+x, alt+x | x, Alt x |
| previous/next_tab | prefix+[/], alt+[/] | [ / ], Alt [ / ] |
| zoom | prefix+z, alt+m | z, Alt m |
| switch_tab | prefix+1..9 + alt(1..9) | 1-9, Alt 1-9 |

舍弃:`Alt + / Alt -`(无 herdr 全局增减动作)→ 用 resize mode 内 `+/-`;`Alt w`(浮动)→ herdr 默认 `prefix+w`=workspace_picker(导航面);`Alt m` 已映射 zoom。

### 无法 1:1 还原项(取舍)

- **持久 pane 模式**:改用 herdr 持久模式 —— 纯导航用 `prefix+g`(navigate,连按 h/j/k/l)、调整用 `prefix+r`、复制/搜索用 `prefix+[`(进去 `/` 或 `?`,n/N,v/Space,y/Enter,q/esc)。
- 浮动 pane / 同步 tab:舍;`BreakPane` 用 `herdr pane move <id> --new-tab` 补脚本(可选);`Move mode` 由 herdr swap 默认 `prefix+shift+h/j/k/l` 近似(语义:位移换位而非方向移);`toggle tab`(zellij Ctrl a)无对应,以 `prefix+[` 翻页近似。
- 终端态半页滚动 Ctrl u/d:仅 copy mode 内有(herdr 默认),终端态不拦截,靠 copy mode/鼠标。
- **zjstatus 模式色块**:`Normal/Pane/Move/Resize/Search/Rename`:herdr 有自带 mode bar(激活时临时替换 );按 Q5 用默认外观不再自定义颜色。

## 软件包与 zsh 别名/函数(迁移)

**新模块** `home/modules/ide/herdr/default.nix`(镜像 zellij/default.nix):
- `home.packages = [ unstablePkgs.herdr ];`
- `home.file.".config/herdr/config.toml".source = (pkgs.formats.toml{}).generate "config.toml" { keys = {...}; keys.indexed = { tabs = "alt"; }; };`(不设其它,全默认)
- (可选)activation:把 `herdr completion zsh` 写入 zsh 补全目录(`programs.zsh.completionsDir`,默认 `~/.local/share/zinit/completions`),保证 zinit 可加载 `_herdr`。
- profile imports:`home/profiles/ide.nix` 与 `clawbot.nix` **新增** `../modules/ide/herdr`(zellij 引用保留)。

**`home/modules/ide/zsh/alias.zsh`**:
- **保留**:`z='zellij'`(并存启动器);`s/sc/ss`(sgpt)、`cp/rm/mv` 等无关别名不动。
- **移除**:`zx`、`zxp`、`zko`、`zl`、`zv`(等价动作改 h 前缀,见下)。
- **新增**:
  - `h='herdr'`
  - `hx='herdr tab close "$HERDR_TAB_ID"'`(原 `zx` 关 tab)
  - `hxp='herdr tab close "$HERDR_TAB_ID"'`(原 `zxp`,关当前 tab 后自动聚焦其它 tab,等价)
  - `hko='herdr-kill-sessions'`
  - `hv='herdr-layout-agent'`

**`home/modules/ide/zsh/fn.zsh`**:
- **删除** `zellij-layout-coding`(对应废弃的 `zl`)。
- **替换** `zellij-layout-agent` → `herdr-layout-agent`(`hv`):用 CLI 重建 zellij agent 布局结构(左 nvim 50% + 右上下两 shell 各 25%):
  ```
  herdr-layout-agent() {
    local path_to_cwd=${1:-$PWD}
    local label="$(basename "${path_to_cwd}")"
    local nvim="$HOME_PROFILE_DIRECTORY/bin/nvim"
    # 须在 herdr 会话内运行(读 HERDR_TAB_ID/HERDR_WORKSPACE_ID);否则提示先 h
    [ -z "${HERDR_TAB_ID:-}" ] && { echo "run inside herdr (use 'h' first)" >&2; return 1; }
    local resp tab_p left right right2
    resp=$(herdr tab create --cwd "$path_to_cwd" --label "$label" --focus) || { echo "$resp" >&2; return 1; }
    left=$(printf '%s' "$resp" | jq -r '.result.root_pane.pane_id')
    # 左:right = 50:50;右再上下 50:50 → 两 shell 各 25%
    right=$( printf '%s' "$(herdr pane split "$left" --direction right  --ratio 0.5 --no-focus)" | jq -r '.result.pane.pane_id')
    right2=$(printf '%s' "$(herdr pane split "$right" --direction down --ratio 0.5 --no-focus)" | jq -r '.result.pane.pane_id')
    herdr pane run "$left" "$nvim"          # 左 panes 装 nvim;右两个保持默认 shell
    herdr pane focus "$left"
  }
  ```
  > 实施时用真实 `herdr tab create` / `pane split` 的 JSON 字段名、`--ratio` 语义核对(`pane split` 返回 `.result.pane.pane_id`);herdr `pane run` 是否需先聚焦等细节就地验证。
- **新增** `herdr-kill-sessions`:`herdr session list --json | jq -r '...非 default/非当前...' | xargs -r herdr session stop`(对应原 `zko` 关停其它 session;字段/过滤条件实施时按真实输出确定)。

> 注:`z` 别名按上表保留(并存),如你希望 `z` 也迁到 `h`,review 时说一声就改这一行。

## Files to modify / 新增

- **新增** `home/modules/ide/herdr/default.nix`、`home/modules/ide/herdr/README.md`
- **改** `home/profiles/ide.nix`、`home/profiles/clawbot.nix`:imports 各加一行 `../modules/ide/herdr`
- **改** `home/modules/ide/zsh/alias.zsh`:删/加别名(见上)
- **改** `home/modules/ide/zsh/fn.zsh`:删 `zellij-layout-coding`;替 `zellij-layout-agent`→`herdr-layout-agent`;加 `herdr-kill-sessions`
- (可选)**改** zsh 补全激活(若 zinit 未自动加载 nixpkgs 包自带的 `_herdr`)

## Reuse（复用现有结构）

- `home/modules/ide/zellij/default.nix` 整套模块骨架(packages+home.file+sessionVariables+activation)镜像。
- `pkgs.formats.toml {}` 生成器(nixpkgs 自带)生成 TOML。
- `unstablePkgs`(已在 `mkSharedArgs` 注入)直接 `home.packages=[unstablePkgs.herdr]`。
- `HOME_PROFILE_DIRECTORY`(自定义 nvim)与 `jq`/`gojq`(sys/json 已进 profile)。
- git 工作流遵循仓库 AGENTS.md:基于最新 `origin/main` 新建 branch + worktree,在 worktree 内改/测/提交,push 后开 PR(PR 不自行合并),完成后删 worktree。

## Steps（实施期执行;规划期不动代码）

- [ ] `git fetch origin`;基于 `origin/main` 建分支 `feat/herdr-integration`;`git worktree add` 新工作树,后续动作均在 worktree 内
- [ ] 新增 `home/modules/ide/herdr/{default.nix,README.md}`;用 `pkgs.formats.toml` 写 `[keys]`+`[keys.indexed]`(其余默认)
- [ ] `home/profiles/ide.nix`、`clawbot.nix` 各加 `../modules/ide/herdr` import
- [ ] 改 `zsh/alias.zsh`(删 zx/zxp/zko/zl/zv;加 h/hx/hxp/hko/hv)
- [ ] 改 `zsh/fn.zsh`(删 coding;替 agent→herdr-layout-agent;加 herdr-kill-sessions)
- [ ] 本地 `herdr --default-config` + 启动日志核对键名可用性(prefix=ctrl+b、`[`/`]`、`comma`、alt 和弦、indexed tabs=alt);必要时回退键名
- [ ] **Verification**:
  - `nh home switch`(或 darwin/nixos 对应切换)生成 `~/.config/herdr/config.toml`;`herdr --default-config` 与之对照无类型/语法报错
  - `h` 进 herdr;逐键验:Ctrl b 前缀、Alt h/j/k/l、Alt 1-9 切标签、Alt [/]、prefix+q 关 pane、prefix+d detach、prefix+c/x、prefix+r 持久 resize、prefix+[ 持久 copy/(搜索、Alt+right/down/n 分屏、Alt+m zoom)。确认前缀改动没误伤
  - `hv <dir>` 重建出左 nvim + 右上下两 shell 结构;`hx`/`hxp` 关 tab;`hko` 关其它 session
  - catppuccin 默认主题与侧栏显示正常(Q5 默认,不强行复刻 zjstatus)
- [ ] worktree 内 commit+push;开 PR(不自行合并);删 worktree

## 实施期修订（相对上方审查记录;以实际代码为准）

- **herdr 版本**:项目当前 pin 的 `nixos-unstable`(rev `624af665…`)中 herdr 是 **0.7.5**,非 0.8.x。0.7.5 默认**无** `swap_pane_*` 绑定,故本模块用 `prefix+shift+l/j` 作分屏(zellij `L`/`J`)在当前版本无冲突。
- **`copy_mode` 改 `prefix+/`**:上方草案曾写 `copy_mode = ["prefix+[", "prefix+/"]`。实测 herdr 会报 `config diagnostic prefix+[: kept keys.previous_tab, disabled keys.copy_mode`(因 `previous_tab` 已占 `prefix+[`)。已改为单值 `copy_mode = "prefix+/"`(对齐 zellij `/` 搜索语义;进 copy mode 后再 `/` 或 `?` 搜)。
- **激活脚本位置**:初稿把 `activation.genHerdrZshCompletion` 误置于顶层 `activation.`,HM 不认该 option(build 报 `option 'activation' does not exist`)。已改 `home.activation.<name>`(与 zellij 模块一致)。
- **前向兼容**:将来升级 flake input 到含 herdr ≥0.8 的 nixpkgs,herdr 会默认 `swap_pane_*=prefix+shift+h/j/k/l`,与分屏键 `prefix+shift+l/j` 冲突。升级前需显式重设 swap_pane_* 或把分屏键改回 `prefix+v`/`prefix+minus`。
- **`hv` 重建**:依赖 `herdr tab create` / `pane split` 的 JSON 字段(`.result.root_pane.pane_id`、`.result.pane.pane_id`)与 `--ratio` 语义。函数已做防御(`// empty` + 非空校验),首次用前建议先跑一次 `herdr tab create --cwd /tmp --label tmp` 观察真实 JSON 再微调 `jq` 路径。
- **本机活体验证**:`just switch-home ide` 并非本机当前切换路径(最近一次为 nix-darwin `just switch-darwin soraliu`)。走 `just switch-darwin soraliu`(需 sudo,重建系统)激活时方写入 `~/.config/herdr/config.toml` 与 `_herdr` 补全;交互式逐键/`hv`/`hko` 验证由用户在真实终端完成。
- **直达层补 `alt+q`/`alt+x`**(后置修复):初稿 `close_pane`/`close_tab` 只绑前缀键,漏了 zellij `shared` 的 `Alt q`/`Alt x`,导致 `Alt q` 不退 pane。已改为数组 `close_pane=["prefix+q","alt+q"]`、`close_tab=["prefix+x","alt+x"]`,与 README 直达层声明一致。
- **开启 agent 完成通知**(后置修复):herdr `ui.toast.delivery` 默认 `off`,致 pi/agent 完成无 toast 提示。已设 `[ui.toast] delivery = "herdr"`(后台 workspace 的 agent 完成/需输入时弹 in-app toast;`ui.sound.enabled` 默认开)。想要系统级横幅改 `"system"`(macOS 优先 `terminal-notifier`)。pi 检测走 herdr 内置屏幕 manifest;更稳的状态/原生会话恢复可一次性 `herdr integration install pi`。
