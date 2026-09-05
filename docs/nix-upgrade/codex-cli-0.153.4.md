# codex-cli 0.153.4 升级报告

## 升级结果

| 项目 | 升级前 | 升级后 |
| --- | --- | --- |
| Nix input | `codex-cli` | `codex-cli` |
| 锁定 revision | `18eb1cac4e17c8cbc40f3a2a83940d8f38ddace5` | `3a0dca3725f6d8b74cfe635a85724d2313731fb4` |
| 锁定时间 | 2026-08-27 | 2026-09-05 |
| 实际应用版本 | `codex-0.150.1` | `codex-0.153.4` |

本次覆盖官方版本区间 `(0.150.1, 0.153.4]`，包含稳定版 `0.151.0`、`0.152.0`、`0.152.1`、`0.153.0`，以及 `0.153.1`–`0.153.4` 一组围绕 GPT-6-Astra 接入与修正的 hotfix。升级目标是获得 TUI 自动重连、远程插件 marketplace、Vim 编辑增强、可操作速率限制提示、更灵活的 MCP 与长时命令配置，以及 GPT-6-Astra 支持；同时纳入凭据保护、sandbox、Guardian 历史与 macOS MCP 启动方面的重要修复。

## 核心新功能与升级原因

### 1. GPT-6-Astra 模型接入，并在无显式配置时成为 bundled 默认模型

- **新功能**：`0.153.1` 起可通过 API 配置 GPT-6-Astra（不改默认模型、不显示在 picker）；`0.153.3` 将其加入 Amazon Bedrock 模型 picker（Mantle 与 Runtime global/US 路由）；`0.153.4` 修复其在 bundled 模型 picker 的可见性，并在**未显式配置 model 时把 GPT-6-Astra 设为 bundled 默认模型**。同期还修正了 Astra 的异步澄清问题指引（仅在工具可用时使用且仅接受文本）和 Fast 档位描述文案。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是在稳定通道上线新一代后端模型，并让没有自定义模型的新会话默认获得该模型，而保留显式配置不被覆盖。属于推断，依据是这些变更集中在 `0.153.x` hotfix 并明确限定“仅在未显式配置时”。
- **解决的问题**：此前 0.153 线无法在 bundled picker/Bedrock 中选用 Astra；新会话默认模型得到统一更新；异步提问行为按工具能力被正确限定。
- **官方来源**：[0.153.1 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.1)、[0.153.2 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.2)、[0.153.3 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.3)、[0.153.4 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.4)、[Backport PR #42605](https://github.com/openai/codex/pull/42605)、[Bedrock catalog PR #42805](https://github.com/openai/codex/pull/42805)、[Bundled default PR #42874](https://github.com/openai/codex/pull/42874)。

### 2. TUI 在 app-server 连接断开后自动重连并保留草稿与记录

- **新功能**：外部 app-server 连接掉线时，TUI 会话自动重连，保留草稿与 transcript，同时把不确定或排队的提交暂停等待审阅。
- **为什么需要**：官方 release notes 未单列动机。据此推断其目的是消除单次连接掉线导致的会话中断与上下文丢失，使终端会话在网络或后端短暂抖动后无需手动重启。属于推断，依据是该功能明确同时处理“重连”与“不确定提交的暂停审阅”两类边界。
- **解决的问题**：避免掉线后草稿/记录丢失和盲目重发未定请求。
- **官方来源**：[0.153.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.0)、[重连 PR #41916](https://github.com/openai/codex/pull/41916)、[草稿保留 PR #41911](https://github.com/openai/codex/pull/41911)、[导航恢复 PR #41918](https://github.com/openai/codex/pull/41918)。

### 3. 插件 CLI 支持远程 marketplace 的列出/安装/移除

- **新功能**：插件 CLI 可直接 list、install、remove 来自远程 marketplaces 的插件，git marketplace 配置可由合并配置升级，catalog 合并 per-repo 配置并报告无效 marketplace 而不隐藏有效插件。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是让插件生命周期管理可在命令行完成，不必手工编辑配置或手工同步 marketplace。属于推断，依据是 CLI 子命令覆盖了 install/remove 全流程。
- **解决的问题**：远程插件安装/更新此前需要在配置或 UI 中操作；catalog 中无效条目不会再掩盖有效插件。
- **官方来源**：[0.153.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.0)、[plugin CLI PR #42150](https://github.com/openai/codex/pull/42150)、[0.151.0 catalog PR #41208](https://github.com/openai/codex/pull/41208)。

### 4. Vim 编辑器：搜索动作与撤销/重做

- **新功能**：`0.152.0` 在草稿中支持 Vim `/`、`?` 搜索、高亮匹配并用 `n`/`N` 重复导航，新建草稿在 Insert 模式启动；`0.153.0` 增加 `u` 撤销与 `Ctrl+R` 重做，保留完整草稿（含粘贴内容与附件）。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是让习惯 Vim 的用户在终端会话内完成搜索与编辑回退，减少误删带来的损失。属于推断，依据是两项功能明确面向 Vim 体验闭环。
- **解决的问题**：此前草稿无法在编辑器内搜索或回退操作；误粘贴/误删后不可恢复。
- **官方来源**：[0.152.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.0)、[Vim 搜索 PR #41586](https://github.com/openai/codex/pull/41586)、[Vim 撤销 PR #41941](https://github.com/openai/codex/pull/41941)、[Vim 重做 PR #42140](https://github.com/openai/codex/pull/42140)。

### 5. 速率限制的可操作提示与提前预警

- **新功能**：`0.152.0` 在 TUI 显示可操作的 rate-limit banner，提供查看用量、管理 credit、重置限额、管理套餐等入口；`0.153.0` 对 Plus/Team 用户在约 5 小时窗口内剩余不足一半时提早预警。后续 `0.152.1`/`0.153.x` 未改动该机制。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是把“被限速”从被动等待变成可立即处理的操作面，并对即将限速的用户提前干预。属于推断，依据是 banner 明确带有四类操作入口与提前预警阈值。
- **解决的问题**：用户被限速时不再只能等待，且能在耗尽前调整使用节奏或套餐。
- **官方来源**：[0.152.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.0)、[0.153.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.0)、[rate-limit banner PR #41742](https://github.com/openai/codex/pull/41742)、[提前预警 PR #42142](https://github.com/openai/codex/pull/42142)。

### 6. MCP 增强：包式 server 名称、逐工具 output_token_limit、扩展可改写工具结果、可配置启动宽限

- **新功能**：MCP server 名称可包含 `:`、`@`、`/`、`.`，支持包式命名贯穿 CLI 命令与认证；单个 MCP 工具可设置 `output_token_limit`，并在 resume 时保持一致截断；扩展可在结果到达模型前检视或替换 MCP 工具结果；optional MCP server 的工具发现宽限期可配置。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是支持把 MCP server 当作包来命名与管理，并对模型可见的工具输出量做更细粒度与可编程控制。属于推断，依据是命名放宽到包式字符、配额下沉到单工具、扩展获得改写钩子。
- **解决的问题**：包风格 MCP server 不再受命名限制；可在工具粒度控制输出长度并在 resume 时保持一致；扩展可实现自定的结果过滤/改写而不必修改工具本身。
- **官方来源**：[0.152.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.0)、[包式名称 PR #41700](https://github.com/openai/codex/pull/41700)、[per-tool limit PR #41421](https://github.com/openai/codex/pull/41421)、[0.151.0 扩展改写 PR #41202](https://github.com/openai/codex/pull/41202)、[0.151.0 启动宽限 PR #41199](https://github.com/openai/codex/pull/41199)。

### 7. 可配置 thread/shellCommand 超时（含超过 1 小时长命令）

- **新功能**：app-server 客户端可为 `thread/shellCommand` 配置超时，支持超过 1 小时的截止时间。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是让 app-server 触发的长时命令不再被统一的较短超时截断。属于推断，依据是 release note 明确强调“包括长于 1 小时”。
- **解决的问题**：通过 app-server 运行的长任务（编译、大型测试、批处理）不再因默认超时被中断。
- **官方来源**：[0.152.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.0)、[shellCommand 超时 PR #41384](https://github.com/openai/codex/pull/41384)。

### 8. TUI 可关闭自动 recap、历史展示完整补丁与终端输入

- **新功能**：`tui.auto_recap = false` 可关闭自动 recap 但保留手动 `/recap`；TUI 历史展示完整 patch、发往后台终端的输入以及每个完成的命令。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是让用户控制自动 recap 的开销，并在历史中保留可复核的完整改动证据。属于推断，依据是 `auto_recap` 作为显式开关且 history 展示范围扩展到 patch 与终端输入。
- **解决的问题**：不希望每次都自动 recap 的用户可直接关闭；历史记录从摘要变为可审计的完整操作流。
- **官方来源**：[0.153.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.0)、[auto_recap PR #42101](https://github.com/openai/codex/pull/42101)、[历史展示 PR #41893](https://github.com/openai/codex/pull/41893)、[patch/终端输入 PR #42107](https://github.com/openai/codex/pull/42107)。

### 9. 凭据刷新进度展示（含 Amazon Bedrock 重新认证）

- **新功能**：TUI 与 `codex exec` 显示 model provider 凭据刷新进度，包括 Amazon Bedrock 重新认证。
- **为什么需要**：官方 release notes 未解释动机。据此推断其目的是让长期会话在 token 过期/刷新时不再静默卡住，用户可见进度。属于推断，依据是把进度推到 TUI 与 exec 两个入口。
- **解决的问题**：凭据过期/刷新过程中的等待不再不可见，避免误判为挂起。
- **官方来源**：[0.152.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.0)、[凭据刷新进度 PR #41239](https://github.com/openai/codex/pull/41239)。

## 重要安全与稳定性修复

### 凭据与云端任务安全

- 云端任务请求拒绝不受信任的后端 URL 并禁用重定向，保护保存的凭据不被转发到非预期主机。
- **官方来源**：[0.152.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.0)、[云端凭据 PR #41403](https://github.com/openai/codex/pull/41403)。

### Sandbox 与权限

- `/cd` 不再削弱 sandbox 限制，跨 TUI 轮次保留恢复后的 permission profiles。
- 切换模型或回退模型时保持工具可用性与 reasoning effort 正确；Ultra reasoning 回退改为 model-aware。
- remote sandbox 改用 executor 实际 home、OS 与路径约定进行强制；deny-read 匹配对齐 executor 路径语义。
- 子 agent token 用量计入 root goal 预算；旧 Guardian 分类在权限状态变化后不再授权动作。
- **官方来源**：[0.151.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.151.0)、[permission profiles PR #41192](https://github.com/openai/codex/pull/41192)、[model tool plans PR #41195](https://github.com/openai/codex/pull/41195)、[executor home PR #41204](https://github.com/openai/codex/pull/41204)、[deny-read 对齐 PR #41209](https://github.com/openai/codex/pull/41209)、[子 agent 预算 PR #41183](https://github.com/openai/codex/pull/41183)。

### Guardian 历史与审批

- Guardian review 历史在压缩、重启与用户创建的 fork 中保留，并尊重 rollback 边界、隔离子 agent 历史；审批评审在历史压缩中保留用户指令、回答与有效授权。
- Full Access 对仅确认类动作跳过 Guardian review；User approval mode 跳过后台 Guardian 评分与预热，敏感动作检查与用户输入请求保持原处理。
- 记住的 MCP 工具审批按所选 app account 隔离；macOS 上相对 MCP 可执行路径启动更可靠。
- `0.152.1` 修复 Guardian 审批评审对 model metadata 提供的 Node REPL 策略的遵守。
- **官方来源**：[0.153.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.153.0)、[Guardian 历史 PR #41879](https://github.com/openai/codex/pull/41879)、[Full Access 跳过 PR #42147](https://github.com/openai/codex/pull/42147)、[User mode 跳过 PR #42256](https://github.com/openai/codex/pull/42256)、[macOS MCP PR #42117](https://github.com/openai/codex/pull/42117)、[0.152.1 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.152.1)。

## 兼容性、迁移与已知限制

- 官方 `0.151.0`–`0.153.4` 发布说明未列出强制迁移步骤，但存在以下行为变化：
- **行为变化**：`update_plan` 规划工具自 `0.152.0` 起默认禁用，需 `tools.update_plan.enabled = true` 重新启用；此前依赖默认规划行为的用户会感受到差异。
- **行为变化**：`0.153.4` 在**未显式配置 model** 时把 bundled 默认模型设为 GPT-6-Astra；已在配置中显式指定 model 的用户不受影响。
- **配置迁移（非破坏）**：`tui.disable_paste_burst` 移至 `[tui]` 下；旧顶层配置仍作为 fallback 支持，无须立即改动。
- **新增配置**：`features.context_management.experimental_mode`（默认禁用）。启用后仅对符合条件的 ChatGPT Plus/Pro/Pro Lite 并使用 Codex backend 的会话激活 token-budget context、history notes 与 `new_context` 工具；API-key、custom provider 与临时结构化 thread 不受影响。
- **API 变化**：app-server thread metadata 新增可空 `model` 与 `reasoningEffort`；通过 `request_user_input_async` 支持结构化异步提问（需 model catalog 启用）。
- **限制**：GPT-6-Astra 的异步问题指引仅在对应工具可用时生效，且仅接受文本。
- **限制**：实验性 context management 仅限部分套餐与 Codex backend，不在 API-key/custom provider 生效。
- **兼容性**：`0.153.1`–`0.153.4` 主要是 GPT-6-Astra 的接入与修正（API 配置、Fast 档位文案、Bedrock catalog、bundled picker 可见性与默认、异步问题指引），不改变请求执行方式。

## 变更范围

- `flake.lock`：仅 `codex-cli` 节点的 `rev`、`lastModified` 与 `narHash` 变化（`18eb1ca` → `3a0dca3`，2026-08-27 → 2026-09-05）；无其他根级 input 或传递 lock 节点变化。
- `docs/nix-upgrade/codex-cli-0.153.4.md`：新增本升级报告。

## 验证证据

| 命令 | 结果 |
| --- | --- |
| `jq -e --arg input 'codex-cli' '.nodes.root.inputs[$input] as $node | {input:$input,node:$node,locked:.nodes[$node].locked}' flake.lock` | 升级前后均确认根 input 指向 `codex-cli` 节点，并取得完整锁定信息。 |
| `nix eval --json '.#homeConfigurations.ide.config.home.packages' --apply 'map (p: p.name)'` | 实际 Codex 包由 `codex-0.150.1` 变为 `codex-0.153.4`；`claude-code-2.1.119` 未变化。 |
| `nix flake update codex-cli` | 成功，仅更新 `codex-cli`：`18eb1ca`（2026-08-27）→ `3a0dca3`（2026-09-05）。 |
| `git diff -- flake.lock` | 仅 `codex-cli` 节点的 revision、`lastModified` 与 `narHash` 变化。 |
| `git diff --check` | 通过，无空白错误。 |
| `nix build '.#homeConfigurations.ide.activationPackage' --no-link` | 退出码 0，成功构建 `codex-0.153.4` 与 Home Manager generation；未创建 result link。 |

构建过程中出现一条 `builtins.toFile` store reference context 警告（与既有 `options.json` 相关），但命令退出码为 0，未阻塞本次构建验证。

未执行 `home-manager switch`、系统 activation（激活）或 live runtime 验证，因此当前系统仍使用原有激活状态。
