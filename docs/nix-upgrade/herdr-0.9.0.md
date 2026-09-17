# Herdr 0.9.0 Nix input 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | `nixpkgs-unstable` → `github:nixos/nixpkgs/nixos-unstable` | 同左 |
| 锁定 revision | `624af665418d3c65d544145b4d34ad696439570e` | `b1b875982b17dabde9b4a37f3e229e74913e6db3` |
| 锁定时间 | 2026-07-26 | 2026-09-16 |
| 实际应用版本 | `herdr-0.7.5` | `herdr-0.9.0` |
| 上游项目 | [`herdrdev/herdr`](https://github.com/herdrdev/herdr)，协议 Apache-2.0 | 同左 |

herdr 包来自 `nixpkgs-unstable`（`home/modules/ide/herdr/default.nix` 中 `home.packages = [ unstablePkgs.herdr ]`）。GitHub 最新 release `v0.9.1`（2026-09-16）尚未进入 nixpkgs，本仓库按现状能拿到的最新版本为 nixpkgs master 的 **0.9.0**。本次用 `nix flake update nixpkgs-unstable` 把 unstable 通道从 2026-07-26 推进到 2026-09-16，让 `ide` 与 `clawbot` 两个 profile 的 herdr 从 0.7.5 升到 0.9.0；并因同类频道推进的连带影响配套更新了 `pi` 封装（详见「升级原因」第 6 节），pi 应用版本不变。

版本区间覆盖 `(0.7.5, 0.9.0]`，即 `0.8.0`（2026-08-03）、`0.8.2`（2026-08-19）、`0.9.0`（2026-09-07）三个发布（上游无 0.8.1 / 0.8.3）。

官方上游来源：herdr 仓库 [`CHANGELOG.md`](https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md) 与 [GitHub Releases](https://github.com/herdrdev/herdr/releases)。nixpkgs 仅用于确认打包版本。

## 升级原因与核心新功能

### 1. 本地 + SSH 多机单窗口管理（0.9.0）

- **新功能**：一个 Herdr 窗口同时管理本机和已保存的 SSH 机器，提供联合 agent 列表、按机器切换的导航、跨机通知与自动重连；新增 `herdr machine` 命令管理连接，单台掉线不影响其余机器（[#3670](https://github.com/herdrdev/herdr/pull/3670)）。
- **为什么需要**：官方给出了多机管理的功能形态，未展开动机。据其表述推断：coding agent 已遍布笔记本与租用服务器，跨机来回 SSH 上下文切换成本高，统一入口可以缩短监控与接管距离。
- **解决的问题**：跨机器运行 agent 时需要开多个终端分别 SSH；现在可以在一个窗口内看全部 agent 状态并在需要时接管。
- **官方来源**：[CHANGELOG 0.9.0 Added #3670](https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md)。

### 2. 多客户端独立视图与按客户端渲染（0.9.0）

- **新功能**：多个客户端可独立查看不同 workspace / tab；各 tab 按自己的查看客户端适配尺寸，共享同一 tab 时最后交互者控制尺寸（[#3526](https://github.com/herdrdev/herdr/pull/3526)）。终端 UI 改为在每个客户端内运行，theme、菜单、copy mode 等展现设置保留在查看侧机器本地，同时降低多客户端 busy 会话的重绘开销（[#3487](https://github.com/herdrdev/herdr/pull/3487)）。
- **为什么需要**：据官方表述推断：此前所有客户端共享同一视图与渲染路径，大输出量会话中多端同时重绘浪费 CPU，且一端改设置影响全部端。
- **解决的问题**：多设备同时 attach 同一会话（笔记本 + 远端 thin client）时视图被互相牵制、渲染抖动的问题。
- **官方来源**：[CHANGELOG 0.9.0 Added/Changed](https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md)。

### 3. 客户端更新不再杀伤兼容的运行中 server（0.9.0）

- **新功能**：客户端更新可以保持兼容 server 及其运行中的 agent 不动；缺失的 server 特性只禁用对应动作而不是拒绝连接。比 endpoint generation 1 旧的 server 需要一次升级；替换远端 server 前会询问，默认 No（[#3509](https://github.com/herdrdev/herdr/pull/3509)）。
- **为什么需要**：据官方表述推断：升级 herdr 客户端时连带杀掉 server 会中断正在运行的 agent 会话，这在 agent 常驻工作流里代价很高。
- **解决的问题**：Nix 管理下二进制翻新后（如 `home-manager switch`），旧客户端/新服务混布阶段的兼容性；运行中的 agent 不再因客户端更新而被无差别停止。
- **官方来源**：[CHANGELOG 0.9.0 Changed #3509](https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md)。

### 4. CLI 与键位直接控制增强（0.8.2）

- **新功能**：
  - 可选 `keys.move_tab_previous` / `keys.move_tab_next` 直接对调 tab 顺序（[#2561](https://github.com/herdrdev/herdr/pull/2561)）。
  - 可选 `keys.resize_pane_left/down/up/right` 单键调整 pane 尺寸，无需进入 resize mode（[#2558](https://github.com/herdrdev/herdr/pull/2558)）。
  - `ui.window_title` 把外层终端窗口标题与会话同步，窗口管理器 / 终端 tab 栏显示活动 workspace 与实际宿主机（[#2627](https://github.com/herdrdev/herdr/pull/2627)）。
  - tab bar 可配置右对齐状态项（zoom 状态、hostname、日期时间、命令输出）；`ui.status_indicators = "symbols"` 为各 agent 状态提供静态形状（[#2260](https://github.com/herdrdev/herdr/pull/2260)）。
  - CLI help 直接指向给 coding agent 用的纯文本指南与内置控制 skill。
- **为什么需要**：据官方表述推断：这些是把日常高频操作（调 tab、pane 尺寸）从 mode 切换降为单键直达，减少打断 agent 监控的操作深度。
- **解决的问题**：键位映射工作流中 tab 重排与 pane 微调此前必须走模式化交互；本仓库 `home/modules/ide/herdr` 的键位映射文档可考虑后续跟进采用。
- **官方来源**：[CHANGELOG 0.8.2 Added](https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md)。

### 5. KDE/发行版无关的发布与许可变化（0.8.0）

- **变化**：herdr 从 AGPL-3.0-or-later 重新许可为 Apache-2.0；GitHub 组织迁至 `herdrdev/herdr`；Nix 构建包含 `herdr --skill` 所需的 bundled agent skill（[#1889](https://github.com/herdrdev/herdr/pull/1889)）。
- **为什么需要**：官方未解释许可动机。据推断：Apache-2.0 对集成方与分发方（含 nixpkgs 在内的下游打包生态）更友好，降低采用摩擦。
- **解决的问题**：AGPL 对二进制再分发与嵌入式集成的合规顾虑；nixpkgs 打包因此可以进入常规渠道。
- **官方来源**：[CHANGELOG 0.8.0 Changed / Fixed](https://github.com/herdrdev/herdr/blob/master/CHANGELOG.md)。

### 6. 配套：pi 封装跟进当前 nixpkgs（pi input，版本不变）

- **背景**：推进 `nixpkgs-unstable` 后，`pi.nix`（旧锁 `f41e1136`）的 `coding-agent/package.nix` 仍引用 `pkgs.typescript-go`，而 nixpkgs 已于 2026-09-08 将该别名改写为 throw（`typescript-go` 合并入 `typescript`）。home-manager 在 darwin 上会把全部 `home.packages` 打进 `home-manager-fonts` buildEnv（[targets/darwin/fonts.nix](https://github.com/nix-community/home-manager/blob/20561be440a11ec57a89715480717baf19fe6343/modules/targets/darwin/fonts.nix)），对每个包强制求值 `derivationStrict`，导致 `homeConfigurations.ide` 构建在 `pi-coding-agent-0.85.1` 上失败：`error: 'typescript-go' has been renamed to/replaced by 'typescript'`。
- **处理**：`nix flake update pi`，把 pi 封装从 `f41e1136` 更新到 [`b900956a`](https://github.com/lukasl-dev/pi.nix/pull/21)（「Support current nixpkgs and migrate to flake-parts」，移除 `typescript-go` 引用）。pi 应用版本保持 `0.85.1` 不变，为纯打包层修复。
- **解决的问题**：恢复 `ide`/`clawbot` profile 可构建性；含 herdr 0.9.0 的整套 unstable 闭包才能落地。
- **官方来源**：[pi.nix PR #21](https://github.com/lukasl-dev/pi.nix/pull/21)、nixpkgs [`aliases.nix`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/aliases.nix)（`typescript-go` 别名 2026-09-08 加入）。

## 重要修复（稳定性 / 正确性）

以下取自三个发布的 Fixed 部分，选取影响本仓库实际使用与稳定性的条目（agent-hosting 场景优先）：

### Pi / agent 集成（本仓库主力 agent）

- **Pi 计划内续跑不再闪断为 idle（0.9.0）**：Oh My Pi 在已排期的 continuation 期间保持 `working`，不再短暂报 idle 提前结束 `agent wait`（[#2851](https://github.com/herdrdev/herdr/issues/2851)、[#3122](https://github.com/herdrdev/herdr/issues/3122)）。
- **Pi 辅助进程不再误报生命周期（0.8.0/0.8.2）**：Pi 的 RPC、JSON、print 模式辅助进程不再冒充交互 TUI 会话认领 pane 生命周期（[#2159](https://github.com/herdrdev/herdr/issues/2159)）；已知 agent 集成把 pane 归属交给确切的进程退出判断，重启 Pi 恢复同一保存会话时生命周期状态正确（[#1648](https://github.com/herdrdev/herdr/issues/1648)）。
- **OMP 集成兼容修复（0.8.0）**：integration install/status/uninstall 尊重 `PI_CONFIG_DIR`（`PI_CODING_AGENT_DIR` 未设时），并拒绝与 Pi 的扩展目录冲突（[#1696](https://github.com/herdrdev/herdr/issues/1696)）。

### Claude Code / Codex / Copilot 检测

- Claude Code：识别全部半圆 spinner 帧，活跃轮次不再显示为 idle（0.8.2，[#2707](https://github.com/herdrdev/herdr/issues/2707) 等）；background MCP 任务与 `Enter to confirm` 类确认提示正确保持 `blocked`（0.9.0）。
- Codex：启动 update dialog 正确报 `blocked`；显式 resume 的会话在首个 prompt 前保存，server 重启后可恢复（0.9.0，[#3301](https://github.com/herdrdev/herdr/issues/3301) 等）。
- Copilot CLI：等待后台 agent 期间保持 `working`（0.9.0，[#3291](https://github.com/herdrdev/herdr/issues/3291)）。

### 终端与输入（中文环境）

- **macOS 中文 IME 提交修复（0.8.2）**：焦点应用请求可打印 key-release 事件时，中文输入法 commit 到达 pane（[#2924](https://github.com/herdrdev/herdr/issues/2924)）。
- `prefix+|` 等绑定识别 macOS Option 与自定义键盘布局产出的字符，精确和弦优先（0.9.0，[#3079](https://github.com/herdrdev/herdr/issues/3079)）；非 ASCII 可打印键与 UTF-8 Alt 和弦可作绑定（0.8.x）。
- Linux runtimes 无终端前台进程组时可用 `HERDR_PROCESS_DETECTION=child-groups` 选择子进程组检测（0.8.0，[#1982](https://github.com/herdrdev/herdr/issues/1982)）。

### 性能与资源

- 多 pane 高频后台输出、滚动条与增强键盘模式下避免冗余隐藏 pane 唤醒与全量终端状态格式化，修复 CPU 回归（0.8.2，[#2550](https://github.com/herdrdev/herdr/issues/2550) 等）。
- 空闲 scrollback 内存占用下降，不减少保留历史（0.9.0，[#3556](https://github.com/herdrdev/herdr/pull/3556)）。
- Unix CLI 在下游管道关闭时安静退出，不再以 exit 101 panic（0.8.2，[#2994](https://github.com/herdrdev/herdr/issues/2994)）——依赖 herdr CLI 的 agent 脚本直接受益。

### 安全与打包

- 稳定直装、自更新与远程助手下载强制校验 GitHub release 资产的 SHA-256 摘要（0.8.2）。
- **Nix 安装通过静态 CDN 获取 crates**，修复此前 endpoint 的下载失败（0.9.0，[#3505](https://github.com/herdrdev/herdr/pull/3505)）——对 Nix 用户的构建可靠性直接相关。
- `herdr config check` 对未知内置主题名报告错误而非静默接受（0.8.2，[#2452](https://github.com/herdrdev/herdr/issues/2452)）。

## 兼容性

- **本仓库 `config.toml` 键全部保留**：`home/modules/ide/herdr/default.nix` 中使用的 `keys.*`（含 `previous_agent`/`next_agent`/workspace 系列）、`keys.indexed.tabs`、`keys.command` 的 `plugin_action`、`ui.show_agent_labels_on_pane_borders`、`ui.toast.delivery = "system"` 在 (0.7.5, 0.9.0] 区间均无改名或删除记录，无需迁移。
- **Breaking：`--no-session` 单进程模式已移除（0.9.0 Removed）**：所有终端 UI 启动都 attach 到后台 server；detach 保留 pane 运行，`herdr server stop` 结束会话。本仓库不使用该模式，无影响。
- **关闭含 worktree 的 workspace 需要显式 group intent（0.9.0，[#2874](https://github.com/herdrdev/herdr/pull/2874)）**：关闭挂有 open worktree workspace 的主 workspace，需要 `workspace close --group` 或 `close_group: true`，否则整组保持打开。本仓库经 herdr worktree 跑 agent（subagent 写手模式），日常 `close_workspace`（`alt+d` / `prefix+shift+d`）遇挂 worktree 组时行为变为"不关"，属安全侧变更。
- **kitty graphics 默认开启（0.9.0 Changed）**：兼容终端中 pane 图像与 graphics API 默认启用；如需关闭设 `terminal.kitty_graphics = false`，旧 `experimental.kitty_graphics` 键仍被接受。纯配置兼容，无迁移动作。
- **server 协议一次性升级**：比 endpoint generation 1 旧的 server（0.7.5 属之）首次接入 0.9.0 客户端时需要一次升级。实际生效路径：`home-manager switch` 换新二进制后，需 `herdr server stop` 重启 server 才能用上 0.9.0（正在运行的 server 仍是内存中的旧二进制）； detach 不会停止 server。
- **生命周期事件语义（0.9.0，[#1270](https://github.com/herdrdev/herdr/pull/1270)）**：新的 lifecycle 订阅从 live 事件开始而非重放历史，API 客户端应先订阅后取快照。仅影响自写 socket API 消费者；herdr-palette 插件使用 `plugin_action` 命令模型，不受影响。
- 许可与组织：AGPL-3.0 → Apache-2.0，仓库地址 `herdrdev/herdr`。`home/modules/ide/herdr/default.nix` 头注释引用的 `https://github.com/herdrdev/herdr` 已是新地址，无需改动。
- `ui.agent_panel_scope` 等 Herdr 自写的旧设置在升级后不再被报为未知键（0.8.2，[#2292](https://github.com/herdrdev/herdr/issues/2292)）；本仓库未使用该键。

## 变更范围

- `flake.lock`：
  - `nixpkgs-unstable` 节点（rev / hash / lastModified，3 行）；
  - `pi` 节点（`f41e1136` → `b900956a`）及其**非共用**传递依赖：新增 `bun2nix-x86_64-darwin`、`nixpkgs-x86_64-darwin`、`nixpkgs-lib`、`treefmt-nix_2` 节点，`flake-parts_2` rev 更新。已验证这些节点仅被 `pi` 子树引用，不影响根 flake 与其他根 input。
- `docs/nix-upgrade/herdr-0.9.0.md`：本报告。
- 无 Nix 表达式改动：herdr 0.9.0 直接来自 nixpkgs `b1b875982b17d`（2026-09-16 unstable）；pi 打包修复来自 pi.nix `b900956a`。

## 验证证据

- `nix eval --json '.#homeConfigurations.ide.config.home.packages' --apply 'map (p: p.name)'` → 更新前 `herdr-0.7.5`，更新后 `herdr-0.9.0`；pi 保持 `pi-coding-agent-0.85.1`。
- `nix eval --json '.#homeConfigurations.clawbot.config.home.packages' --apply 'map (p: p.name)'` → 更新后 `herdr-0.9.0`。
- `nix eval` 全量 force 扫描（116 包逐一 `tryEval (seq p.outPath …)`）→ 修复 pi 后无异常包（修复前 `pi-coding-agent-0.85.1` 抛 `typescript-go` rename 错误）。
- `nix flake update nixpkgs-unstable` → `624af66` (2026-07-26) → `b1b8759` (2026-09-16)。
- `nix flake update pi` → `f41e1136` → `b900956a` (2026-09-16)。
- `git diff --check` 通过。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` → 构建通过。
- `nix build '.#homeConfigurations.clawbot.activationPackage' --no-link` → 构建通过。
- 未执行任何 `switch` / 激活操作：本机与 clawbot 环境需用户自行执行 `switch-darwin` / `switch-home` 生效；生效后按上文「server 协议一次性升级」重启 herdr server（`herdr server stop`）以载入 0.9.0 二进制。
