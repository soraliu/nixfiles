# claude-code 2.1.296 升级报告

## 升级结果

| 项目 | 升级前 | 升级后 |
| --- | --- | --- |
| Nix input | `claude-code` | `claude-code` |
| 锁定 revision | `f3eb770e763b685def35939621026433d31d0a18` | `7a91b64f9378dcff2180dc35b9ba033754d93b0a` |
| 锁定时间 | 2026-04-24 | 2026-10-11 |
| 实际应用版本 | `claude-code-2.1.119` | `claude-code-2.1.296` |

本次覆盖官方版本区间 `(2.1.119, 2.1.296]`，共 146 个版本（2.1.120 – 2.1.296）。这是近半年的跨度，核心内容是：Anthropic 模型全线换代（Opus 5 → 5.5、Sonnet 5 → 5.5、Haiku 5.5、Fable 5 → 5.1，全部原生 1M context），`/goal` 持续任务模式、fallback 模型链、auto mode 免 opt-in 与大量判定自动化，以及大范围的启动/长会话性能优化与安全硬化。

## 核心新功能与升级原因

### 1. 新一代模型支持（本次升级的最主要动机）

- **新功能**：区间内依次加入 Opus 4.8（`2.1.154`）、Fable 5（`2.1.170`，Mythos 级模型开放通用）、Sonnet 5（`2.1.197`，明确写有 "Update to version 2.1.197 for access"）、Opus 5（`2.1.219`）、Fable 5.1（`2.1.257`）、Opus 5.5（`2.1.280`，新默认 Opus）、Sonnet 5.5（`2.1.284`，新默认 Sonnet）、Haiku 5.5（`2.1.293`，新默认 Haiku）。新模型全部为原生 1M-token context；配套还有 1M context 的 auto-compact 改进（`2.1.260`：临近 1M 上限提前压缩，超大 context 的恢复压缩不再 10 分钟超时）。
- **为什么需要**：官方 changelog 对 Sonnet 5 明确标注不升级到 2.1.197 以上就无法使用该模型，各模型条目均写明"now the default"。持续停留在 4 月的 2.1.119 意味着无法选用任何新一代模型与新的默认模型。
- **解决的问题**：CLI 版本过旧导致新模型不可用；新默认模型GEN的 1M context 长任务缺少配套压缩策略的问题也被一并覆盖（推断依据：changelog 同版本段落将两者并列发布）。
- **官方来源**：[CHANGELOG 2.1.197](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)、[Claude Sonnet 5 发布公告](https://www.anthropic.com/news/claude-sonnet-5)、[Claude Fable 5 发布公告](https://www.anthropic.com/news/claude-fable-5-mythos-5)。

### 2. `/goal` 持续任务模式

- **新功能**：`2.1.139` 新增 `/goal` 命令——设定一个完成条件，Claude 跨多个 turn 持续工作直到目标达成；支持交互模式、`-p`（headless）与 Remote Control，并以覆盖面板实时显示 elapsed/turns/tokens。
- **为什么需要**：官方 changelog 未解释动机。据此推断其目的是把"多轮 LoopAgent 式长任务"变成一等公民，免得用户手动反复驱动会话。属于推断，依据是该功能同时覆盖三种运行形态并自带计时面板，是完整产品化设计。
- **解决的问题**：长任务需要人工逐步确认推进；起步/中途切换目录会破坏 prompt cache（配套 `/cd` 同样在 `2.1.169` 加入）。
- **官方来源**：[CHANGELOG 2.1.139 / 2.1.169](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

### 3. fallback 模型链与更稳的 API 容错

- **新功能**：`2.1.166` 新增 `fallbackModel` 设置与 `--fallback-model`（最多三级按序回退），主模型过载或不可用时自动切换；意外 non-retryable 错误会先在 fallback 模型上重试一次（认证、限速、请求超限、传输错误仍然直接报错）。`2.1.152` 起主模型 404 时整个会话切到 fallback 而不是每条请求都失败；`2.1.181` 连接在 thinking 中途断开改为自动重试。
- **为什么需要**：官方 changelog 未解释动机。据此推断其目的是提高高峰期可用性——过去单模型过载即中断工作流。属于推断，依据是修复措辞均为"instead of failing every request"。
- **解决的问题**：API 过载/模型下线时任务直接失败；thinking 断流需要手动重发。
- **官方来源**：[CHANGELOG 2.1.166 / 2.1.181](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

### 4. auto mode 成熟：免 opt-in，判定自动化

- **新功能**：`2.1.152` 起 auto mode 不再需要 opt-in 同意；`2.1.218` 起危险 `rm`、后台 `&`、可疑 Windows 路径检查与 plan mode 下静态分析无法证明只读的 Bash 命令，都交给 auto-mode 分类器裁决而不是弹权限框；`2.1.210` 起分类器默认用 Sonnet 5 并在会话首个请求上验证。`2.1.257` 为 auto mode 增加 Containment Escape 规则，云凭据抓取、出网逃逸、跨租户访问不再被自动放行。
- **为什么需要**：官方 changelog 未解释动机。据此推断其目的是让自动化工作流不再被权限弹窗反复打断，同时用模型分类器保住安全底线。属于推断，依据是多个版本持续把"静态规则弹框"改为"分类器裁决"。
- **解决的问题**：权限弹窗噪音；`status.showUntrackedFiles=no` 等配置能骗过 git status 检查（`2.1.236`）。
- **官方来源**：[CHANGELOG 2.1.152 / 2.1.218 / 2.1.257](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

### 5. 启动与长会话性能的系统性优化

- **新功能**：启动时间多项改进——`2.1.243`（sandbox 与 MCP bring-up 不阻塞首帧，bare 启动跳过子命令注册）、`2.1.268`（`--continue`/`--resume` 会话立即恢复、首条消息不再重读整个 transcript、workflows 不再逐个解析脚本）、`2.1.277`（headless 首 turn 不等 CLAUDE.md 目录查找）、`2.1.281`（git 读取、启动遥测、Bedrock/Vertex 模型升级检查移出首帧）、`2.1.283`（`claude -p` 不再加载交互 UI）。长会话响应性——`2.1.269`/`2.1.273`（transcript/hook 更新不再全量重处理对话）、`2.1.257`（渲染减负，流式输出不再随回复变长变慢）、`2.1.293`（修复 HTTP MCP 连接把每个历史请求留存在内存直到关闭的泄漏）、`2.1.235`（云后台会话 CPU/内存）。`2.1.251` 还把二进制缩小了 2.5 MB（剥离 6 门稀有语言高亮）。
- **为什么需要**：官方 changelog 未解释动机，但措辞直接指向"长会话卡顿、启动慢"是核心痛点（"long sessions stay responsive"、"no longer slows down"）。动机部分属于推断，依据是同类修改贯穿 20+ 个版本。
- **解决的问题**：老版本在大 transcript、多 subagent、MCP 重连场景下的卡顿与内存增长。
- **官方来源**：[CHANGELOG 2.1.243 / 2.1.268 / 2.1.269 / 2.1.293](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

### 6. 工作流可用性：grep 后直接编辑、并行工具独立失败、worktree 安全

- **新功能**：`2.1.160`/`2.1.144` 起单文件 `grep`/`egrep`/`head`/`tail` 视图满足 read-before-edit 检查，"no match"（exit 1）不再算命令失败；`2.1.161` 并行工具调用中一个 Bash 失败不再取消同批其他调用；`2.1.128` `EnterWorktree` 改为从 local HEAD 建（不丢未推送提交）；`2.1.143` worktree 清理在 `git worktree remove` 失败时不再回退 `rm -rf`（保护 gitignored/进行中文件）；`2.1.224` 取消每会话 200 个 subagent 的生成上限，`2.1.260` 取消 subagent 后台命令 1 小时超时。
- **为什么需要**：官方 changelog 未解释动机。据此推断这些是对日常高频摩擦点的集中修复（误判只读、误删文件、误取消并行任务）。属于推断，依据是条目均以问题后果收尾（"unpushed commits are no longer dropped"、"preventing loss of files"）。
- **解决的问题**：Edit 前必须额外 Read 导致的报错；并行批次一损俱损；worktree 数据丢失风险；大型 agent 编排被上限卡住。
- **官方来源**：[CHANGELOG 2.1.160 / 2.1.161 / 2.1.128 / 2.1.143 / 2.1.224](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

### 7. `/code-review` 重做与 skills 生态完善

- **新功能**：`2.1.147` 将 `/simplify` 重命名并重做为 `/code-review`，按指定 effort 级别报告正确性 bug（如 `/code-review high`），支持 `--comment` 把发现以行内评论贴到 GitHub PR；`2.1.218` 起在后台 subagent 运行不占主对话。skills 方面：`2.1.157` `.claude/skills` 目录插件自动加载（无需 marketplace）、`2.1.152` `/reload-skills` 免重启重扫、`2.1.261` `/skill-doctor` 展示各 skill 使用率与 context 开销、`2.1.198` 新增内置 `/dataviz` skill。
- **为什么需要**：`/simplify` 条目明确写旧清理修复行为已移除、改为找 correctness bug，是产品方向调整（官方变更说明本身即为动机）；skills 生态部分推断为降低自定义能力接入门槛。skills 动机属推断，依据是三个版本把"发现-加载-度量"链路补齐。
- **解决的问题**：code review 从占屏任务变为后台任务；本地/公司内 skills 部署不再需要 marketplace；skill 越装越多导致 context 膨胀现在可度量可修剪。
- **官方来源**：[CHANGELOG 2.1.147 / 2.1.218 / 2.1.157 / 2.1.261](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

### 8. 安全硬化（多项跨版本）

- **新功能**：`2.1.296` 修复共享 transcript 与 debug 日志中 secret redaction 漏网（键无值、shell 字符串内 JSON）；`2.1.196` `claude mcp list`/`get` 不再 spawn 仓库自批准的 `.mcp.json` 服务器（未信任工作区显示 `⏸ Pending approval`）；`2.1.275` npm 来源插件改为 `npm pack --ignore-scripts` 拉取并做完整性校验（安装脚本不再执行）；`2.1.228` claude.ai 同步 skills 不再遮蔽本地命令/MCP prompts、内容过滤消毒；`2.1.210` Agent 工具防间接 prompt injection；`2.1.166` 跨会话 `SendMessage` 不再携带用户权限（拒绝转发权限请求）；`2.1.292` 修复 UNC 网络路径文件读取绕过权限提示（PreToolUse hook + auto mode）；`2.1.207` 修复插件配置 shell 注入（`${user_config.*}` 已拒绝）。
- **为什么需要**：这些条目自带 "Security:" / "Hardened" 官方标记，动机明确为供应链与权限模型加固。
- **解决的问题**：敏感信息进入日志/共享文案、恶意仓库通过 MCP/插件/skill 图谋提权、注入攻击面。
- **官方来源**：[CHANGELOG 2.1.296 / 2.1.196 / 2.1.275 / 2.1.292](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)。

## 兼容性

### 破坏性变更

1. **TodoWrite/Todo 工具在新模型上默认不可用**（`2.1.233`）：Opus 4.8、Sonnet 5、Fable 5、Mythos 5 及更新模型中 `TaskCreate/Get/Update/List`、`TodoWrite` 不再暴露给模型；如依赖需设 `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` 恢复。
2. **subagent 默认不再嵌套生成 subagent**（`2.1.217`）：需要深层嵌套时设 `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`。
3. **Task 工具 `mode` 参数弃用**（`2.1.212`）：已被忽略，subagent 默认继承父会话权限模式。
4. **触发词与命令重命名/移除**：dynamic-workflow 触发词 `workflow` → `ultracode`（`2.1.160`，`2.1.284` 再变为 `/effort` 独立开关不再绑定 xhigh）；`/simplify` → `/code-review` 且旧清理行为移除（`2.1.147`）；`ultraplan` 移除（`2.1.222`）；`/agents` 向导移除（`2.1.198`）；`TeamCreate`/`TeamDelete` 工具移除（`2.1.178`）；`TaskOutput` 工具移除、`taskOutputMaxChars`/`TASK_MAX_OUTPUT_LENGTH` 失效（`2.1.277`）。
5. **环境变量**：`CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` 于 `2.1.160` 移除（`2.1.154` 弃用）；`keybindingFlavor` 失效，行编辑键统一为 Bash 习惯（`2.1.261`）。
6. **项目级 settings 安全收紧（可能影响仓库内 `.claude/settings*.json`）**：`env` 不再能设 `CLAUDE_CONFIG_DIR`、`CLAUDE_CODE_TMPDIR`、`TMPDIR`/`TMP`/`TEMP`（`2.1.251`，Windows 另有 `ALLUSERSPROFILE` 等一组，`2.1.285`）；`autoMode` 不再从 `.claude/settings.local.json` 读取（`2.1.207`）；`pluginConfigs` 不再从 project settings 读取（`2.1.207`）；Remote Control 与 Claude in Chrome 不能被 repo 级设置开启（`2.1.222`/`2.1.290`）；`CLAUDE_CODE_DISABLE_ATTACHMENTS` 同理（`2.1.290`）；`sandbox.ripgrep` 仅 user/managed/`--settings` 可设（`2.1.232`）。
7. **MCP**：WebSocket MCP 消息超 16 MiB 直接断连（`2.1.295`，与其他 transport 对齐）；支持 MCP `2025-11-25` 协议的 URL prompts（登录等），个别服务器升级后连不上的需在配置加 `"bareElicitationCapability": true`（`2.1.287`）。
8. **OTEL 遥测**：子进程（Bash/hooks/MCP/LSP）不再继承 `OTEL_*`（`2.1.128`）；已记录 prompt 内容的部署在升级后会**开始**收到 `claude_code.assistant_response`（模型响应正文）日志，需 `OTEL_LOG_ASSISTANT_RESPONSES=0` 才保持仅 prompts——隐私敏感部署务必注意（`2.1.193`）。
9. **Windows**：Git for Windows 不再是硬依赖，缺失时回退 PowerShell 作为 shell 工具（`2.1.120`）。
10. **其他**：`AskUserQuestion` 对话框不再默认 auto-continue（`2.1.200`）；`anthropic-skills`/`claude-ai` namespace 的 skills/commands 不再加载（`2.1.282`）；自托管 runner 的 wrapper 若追加 `--system-prompt` 必须改用 `--system-prompt-file`（`2.1.281`）。

### 迁移要求

- 依赖上述被移除/重命名能力的用户脚本、hooks 与 muscle memory 需要对照第 4、5、8 条调整。
- 诊断入口收敛：启动横幅类信息（setup issues、claude command broken、marketplace 提示等）多数移入 `/doctor` 与 `/status`，排障习惯从"看启动输出"改为"跑 `/doctor`"。

### 已知限制

- 大量能力（Claude apps gateway、Claude Tag、Routines、Claude in Chrome、Cowork、cloud sessions、`/usage-credits`）依赖 claude.ai 订阅或 Enterprise 计划，纯 API-key/CLI 场景不可用。
- 1M context 需要 usage credits（`2.1.268` 明确提示 mid-session 开启需重启生效）；fast mode 为 2 倍价格（`2.1.154`）。
- 默认模型在升级后随各代发布推进（最终 Sonnet 5.5 / Opus 5.5 / Haiku 5.5），费用结构确认如旧无变化，但 fast mode 定价模型已换代。

## 变更范围

- 文件：仅 `flake.lock`（新增本报告 `docs/nix-upgrade/claude-code-2.1.296.md`）。
- lock 节点变化：
  - `claude-code`：rev `f3eb770` → `7a91b64`；其 inputs 中移除 `flake-utils` 引用（上游 `sadjow/claude-code-nix` 已不再依赖 flake-utils），新增 `systems` 引用。
  - 新增 `systems` 节点（`github:nix-systems/default` `d36eeed`，2026-10-05），仅被 `claude-code` 使用。
  - 原 `systems` 节点（`da67096`，被根 flake 的 `flake-utils` 链引用）重命名为 `systems_2`，**锁定内容不变**。
  - 其余根 inputs（nixpkgs、home-manager、codex-cli 等）锁定完全未动；实际版本验证 `codex-0.153.4` 不变。
- 遗留小提示：根 `flake.nix` 中 `claude-code.inputs.flake-utils.follows = "flake-utils"` 现指向上游已不存在的 input，仅产生 `warning: input 'claude-code' has an override for a non-existent input 'flake-utils'`，不影响功能；可在后续维护中删除该 override 消除 warning。

## 验证证据

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| 锁定更新 | `nix flake update claude-code` | 成功，`f3eb770` (2026-04-24) → `7a91b64` (2026-10-11) |
| 变更范围审查 | `git diff -- flake.lock` + 与 `origin/main` 逐节点比对、`git diff --check` | 仅 claude-code 相关节点变化，无空白错误 |
| 构建 | `nix build '.#homeConfigurations.ide.activationPackage' --no-link` | 成功（`BUILD OK`），实际构建 `claude-code-2.1.296.drv` |
| 版本对比 | `nix eval '.#homeConfigurations.ide.config.home.packages' --apply 'map (p: p.name)'`（升级前后） | `claude-code-2.1.119` → `claude-code-2.1.296`；`codex-0.153.4` 不变 |

未执行：`home-manager switch` 等激活操作（用户未要求），`claude --version` / `claude /doctor` 的运行时冒烟也未执行——live 验证待用户切换后自行确认。
