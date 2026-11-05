# Codex CLI 0.166.0 Nix input 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | `codex-cli` → `github:sadjow/codex-cli-nix` | 同左 |
| 锁定 revision | `3a0dca3725f6d8b74cfe635a85724d2313731fb4` | `f9eefb1b70318cf8f4a5925d1fd5ceb2dddb0f51` |
| 锁定时间 | 2026-09-05 | 2026-10-29 |
| 实际应用版本 | `codex-0.153.4` | `codex-0.166.0` |
| 上游项目 | [`openai/codex`](https://github.com/openai/codex) | 同左 |

本仓库消费点：`home/modules/ai/codex/default.nix`（`codex-cli.packages.${system}.default`），ide 系与 clawbot 两个 profile 均安装。

版本区间覆盖 `(0.153.4, 0.166.0]`，即 0.154.0 ~ 0.166.0 共 13 个 minor 发布（上游官方 `CHANGELOG.md` 仅剩 Unreleased 占位，本文全部取自 GitHub Releases 逐 tag 核对）。

## 升级原因与核心新功能

### 1. 原生 Git worktree 会话（0.154 引入实验，0.156 默认开启）

- **新功能**：`codex --worktree` 或 `/worktree` 为新会话/fork 会话创建隔离 checkout，可在 agent command center 浏览、恢复、按所有权删除（0.154 [#42652](https://github.com/openai/codex/pull/42652)；0.156 默认开启 [#45276](https://github.com/openai/codex/pull/45276)；0.156 状态过滤与 worktree 会话创建 [#46839](https://github.com/openai/codex/pull/46839)）。
- **为什么需要**：官方未单独说明动机。据功能形态推断：与 Claude Code 的 `--worktree`、本仓库 herdr worktree 工作流同构，长任务隔离开发分支避免污染主工作区。
- **解决的问题**：codex 此前只能整仓就地改文件；现在可开隔离 worktree 跑高风险任务。
- **官方来源**：[Release 0.154.0](https://github.com/openai/codex/releases/tag/rust-v0.154.0)、[Release 0.156.0](https://github.com/openai/codex/releases/tag/rust-v0.156.0)。

### 2. 全屏 TUI 与 transcript 体验（0.156 引入，0.157 起默认全屏）

- **新功能**：`/tui` 可选全屏 UI，含 transcript 搜索、鼠标选择、右键复制（0.156 [#46732](https://github.com/openai/codex/pull/46732)）；0.157 起全屏 transcript 默认开启并支持 Shift-click 扩选（[#47178](https://github.com/openai/codex/pull/47178)）；0.166 增加键盘驱动选择（词/行/页 motion + 集成搜索，[#57221](https://github.com/openai/codex/pull/57221)）；0.162 `/copy` 导航复制块、`Ctrl+Insert`、`tui.mouse_scroll_speed`（[#50434](https://github.com/openai/codex/pull/50434)）。
- **为什么需要**：官方未展开动机。据推断：长 transcript 回看与复制是 CLI agent 高频操作，全屏模式补齐终端原生体验。
- **解决的问题**：此前 transcript 浏览受滚动缓冲区限制，选择复制需要终端鼠标模式配合。
- **官方来源**：[Release 0.156.0](https://github.com/openai/codex/releases/tag/rust-v0.156.0)、[Release 0.157.0](https://github.com/openai/codex/releases/tag/rust-v0.157.0)、[Release 0.162.0](https://github.com/openai/codex/releases/tag/rust-v0.162.0)、[Release 0.166.0](https://github.com/openai/codex/releases/tag/rust-v0.166.0)。

### 3. 会话中途转向（steering）与即时打断

- **新功能**：模型响应期间可发送 follow-up 立即转向（0.163 [#51812](https://github.com/openai/codex/pull/51812)，打断同时停止活跃 Code Mode cell 与嵌套工具调用）；opt-in `instant_interrupt` 在模型响应或长 code-mode 调用期间接受新输入（0.159 [#48135](https://github.com/openai/codex/pull/48135)）；0.154 支持在工作期间内联回答问题，不丢主草稿（[#42891](https://github.com/openai/codex/pull/42891)）。
- **为什么需要**：官方未说明动机。据推断：等待长响应完成才能纠偏的代价高，转向能显著减少 wasted turns。
- **解决的问题**：此前响应中只能 Esc 打断重来，输入丢失。
- **官方来源**：[Release 0.163.0](https://github.com/openai/codex/releases/tag/rust-v0.163.0)、[Release 0.159.0](https://github.com/openai/codex/releases/tag/rust-v0.159.0)、[Release 0.154.0](https://github.com/openai/codex/releases/tag/rust-v0.154.0)。

### 4. `/presets`、`/config` 搜索与 leader key（0.163–0.164）

- **新功能**：十个编号 `/presets` 槽位保存可复用 prompt/slash command（0.164 [#54380](https://github.com/openai/codex/pull/54380)）；`/model`、`/permissions` 接受内联参数直接设模型/推理力度/权限 profile（0.164 [#54378](https://github.com/openai/codex/pull/54378)）；`/config` 跨类目搜索偏好并即时生效（0.163 [#52990](https://github.com/openai/codex/pull/52990)）；`/keymap` 可配 leader key（默认 `Ctrl+X`，0.163 [#52273](https://github.com/openai/codex/pull/52273)）。
- **为什么需要**：官方未展开动机。据推断：设置项数量增长后，搜索与快捷入口降低记忆负担。
- **解决的问题**：高频 prompt 模板与设置查找此前需手工重打。
- **官方来源**：[Release 0.164.0](https://github.com/openai/codex/releases/tag/rust-v0.164.0)、[Release 0.163.0](https://github.com/openai/codex/releases/tag/rust-v0.163.0)。

### 5. 模型目录更新：GPT-6 家族与 Vertex AI provider

- **新功能**：GPT-6 Sol / Luna（0.157 [#47332](https://github.com/openai/codex/pull/47332)）；GPT-6.1 Sol 成为默认模型（0.161 [#49318](https://github.com/openai/codex/pull/49318)）；GPT-6.1 Terra 进入 bundled / Vertex / Bedrock 目录（0.165 [#57337](https://github.com/openai/codex/pull/57337)、0.166 [#57293](https://github.com/openai/codex/pull/57293)）；内置 Google Cloud Vertex AI provider（`model_provider = "gcp"`，0.165 [#56265](https://github.com/openai/codex/pull/56265)）；会话中途默认可改推理力度（0.165 [#56163](https://github.com/openai/codex/pull/56163)）。
- **为什么需要**：新模型目录与默认模型随上游模型发布滚动；Vertex provider 使 GCP 账号可用官方接入层。
- **解决的问题**：旧目录模型（GPT-5.x）逐步退役的迁移路径。
- **官方来源**：同上各 release 页。

### 6. 值得记录的安全强化（0.154–0.166 持续）

- 终端输入审批默认启用（elevated permissions 命令，0.158 [#47799](https://github.com/openai/codex/pull/47799)）；凭据脱敏覆盖远程 Bash 与 Zsh snapshot（0.164 [#54309](https://github.com/openai/codex/pull/54309)）；沙箱逃逸面持续收口（macOS 只读文件句柄写、Linux 特权 socket、Windows 进程逃逸、case-variant 元数据路径、可替换符号链接，见各 release Bug Fixes）；`.aws` 目录默认纳入可写根保护（0.159 [#48176](https://github.com/openai/codex/pull/48176)）。
- **为什么需要**：agent 执行面扩大后审批与沙箱边界需同步收紧。
- **官方来源**：各 release 页 Bug Fixes 段。

## 兼容性

- **`codex mcp-server` 入口点已移除（0.154 Chores [#42993](https://github.com/openai/codex/pull/42993)）**：本仓库不使用，无影响。
- **`tui.prompt_suggestions` 设置与 follow-up 建议已移除（0.159 Chores [#48621](https://github.com/openai/codex/pull/48621)）**：本仓库 `home/modules/ai/codex` 只装包不写 `config.toml`，无影响。
- **不再捆绑 patched zsh（0.163 Chores [#52160](https://github.com/openai/codex/pull/52160)）**：改用标准 shell executor；使用旧 shell flags 的配置会收到迁移提示。本仓库不写 codex shell 配置，无影响。
- **personality 设置 `friendly` / `pragmatic` 已不再选择响应风格（0.156 文档澄清 [#45809](https://github.com/openai/codex/pull/45809)）**：仓库未使用。
- **Daybreak 需 `--enable cli_daybreak` 或 `features.cli_daybreak=true` 显式开启（0.161 [#49856](https://github.com/openai/codex/pull/49856)）**：仓库未使用。
- **`plugin-creator` skill 已移除（0.159 [#48604](https://github.com/openai/codex/pull/48604)）**：仓库未使用。
- 无上游声明的配置迁移要求落在本仓库消费面上。

## 变更范围

- `flake.lock`：`codex-cli` 节点（rev / narHash / lastModified，共 4 行），无传递依赖节点新增或删除（该 input `nixpkgs.follows = "nixpkgs-unstable"`，共用根节点）。
- `docs/nix-upgrade/codex-cli-0.166.0.md`：本报告。
- 无 Nix 表达式改动。

## 验证证据

- `nix eval --json '.#homeConfigurations.ide.config.home.packages' --apply 'map (p: p.name)'` → 更新前 `codex-0.153.4`，更新后 `codex-0.166.0`。
- `nix eval --json '.#homeConfigurations.clawbot.config.home.packages'` → 更新后 `codex-0.166.0`。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` → 构建通过。
- `nix build '.#homeConfigurations.clawbot.activationPackage' --no-link` → 构建通过。
- `git diff --check` 通过；lock diff 仅 4 个目标节点变化（节点总数 34 → 34）。
- 未执行 `switch` / 激活操作：本机生效需用户自行 `switch-darwin`。
