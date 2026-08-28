# codex-cli 0.150.1 升级报告

## 升级结果

| 项目 | 升级前 | 升级后 |
| --- | --- | --- |
| Nix input | `codex-cli` | `codex-cli` |
| 锁定 revision | `36fefe14f5549c2751afa313bfcc8582eb025707` | `18eb1cac4e17c8cbc40f3a2a83940d8f38ddace5` |
| 实际应用版本 | `codex-0.149.0` | `codex-0.150.1` |

本次覆盖官方版本区间 `(0.149.0, 0.150.1]`，即 `0.150.0` 和 `0.150.1`。升级目标是获得跨任务协作、终端交互和中断自动化能力，同时纳入信任边界、凭据保护、MCP、终端退出与上下文压缩方面的重要修复。

## 核心新功能与升级原因

### 1. 在终端中引用和管理其他 Codex 任务

- **新功能**：可通过 `@` mention 引用其他 Codex 任务，并让 agent 读取、创建或向任务发送消息；任务管理覆盖列出、读取、等待、创建、fork、消息、重命名、归档和恢复。
- **为什么需要**：官方 PR 说明此前 TUI（Terminal User Interface，终端用户界面）不支持 app-server 的动态工具调用，因此 agent 无法在 TUI 会话中检查或管理其他任务。
- **解决的问题**：跨任务协作不再需要离开当前终端会话手动搬运上下文；引用采用有界的实时 thread reference，并优先显示当前工作目录的任务。
- **官方来源**：[0.150.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.150.0)、[任务管理 PR #40308](https://github.com/openai/codex/pull/40308)、[任务 mention PR #40315](https://github.com/openai/codex/pull/40315)。

### 2. 更直接的终端内容复用与导航

- **新功能**：`/copy` 可选择复制完整响应、单个代码块或引用块；无标题任务自动获得描述性标题，`/rename` 会建议可编辑标题；受支持终端中的 Markdown 链接显示为可点击标签；另有权限模式循环快捷键和 Vim `.` 重复编辑。
- **为什么需要**：官方发布说明未统一说明动机。根据这些功能减少手工选择、命名和重复键入的行为，推断其目的是降低长会话中的操作摩擦和复制错误。
- **解决的问题**：无需先用鼠标精确选择响应片段；任务列表更易辨认；支持的终端可以直接打开链接；键盘工作流更连贯。
- **官方来源**：[0.150.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.150.0)、[`/copy` PR #39997](https://github.com/openai/codex/pull/39997)。

### 3. 新增 `Interrupt` hook

- **新功能**：顶层 turn 被中断时，可在 abort 事件前运行命令或 MCP（Model Context Protocol，模型上下文协议）handler；hook 可取得 session、turn、transcript、工作目录、模型和权限模式信息。
- **为什么需要**：官方 PR 未单列动机。根据事件顺序与输入内容，推断其用于在用户中断后可靠执行审计、通知或清理，而不必把这类逻辑散落在交互流程中。
- **解决的问题**：中断此前缺少专用自动化触点；现在 transcript 会先 flush，再调用 hook，并支持命令与 MCP handler。
- **官方来源**：[0.150.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.150.0)、[Interrupt hook PR #40511](https://github.com/openai/codex/pull/40511)。

## 重要安全与稳定性修复

### 信任边界和凭据保护

- 不受信任项目不再提供项目级 `AGENTS.md` 指令，用户级指令仍保留；运行时切换信任状态时会重新加载适用指令。
- 托管的 `deny_read` 规则在权限更新或请求级 sandbox policy 中继续强制执行。官方说明其必要性是防止运行时权限更新削弱托管文件系统限制。
- app-server 诊断日志加强凭据脱敏，覆盖 provider、认证刷新和 attestation 字段。
- **解决的问题**：项目内容无法在未获信任时注入项目级 agent 指令，权限切换不能绕过托管拒读规则，诊断日志更不易泄漏认证材料。
- **官方来源**：[0.150.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.150.0)、[不受信任项目指令 PR #39837](https://github.com/openai/codex/pull/39837)、[`deny_read` PR #40004](https://github.com/openai/codex/pull/40004)。

### MCP、终端退出与模型兼容性

- 修复 remote MCP Bearer token 查找、required server 启动以及旧 executor 兼容性。
- 修复 Unix 下 detached process 保留终端或输出 channel 填满时导致的 shutdown hang；PTY I/O 改为可取消的非阻塞处理。
- 修复 Amazon Bedrock 模型的 conversation compaction 与 multi-agent 兼容性。
- **解决的问题**：减少远程 MCP 启动失败、CLI 退出卡住和 Bedrock 会话压缩/多 agent 异常。
- **官方来源**：[0.150.0 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.150.0)、[Unix PTY 修复 PR #40460](https://github.com/openai/codex/pull/40460)。

### 0.150.1 retained-image 压缩预算修复

- remote compaction 默认把保留图片计入既有 token budget，并按需裁剪较旧图片。
- **为什么需要**：此前被保留的图片没有默认计入远程压缩预算，可能让实际上下文超过预期预算。
- **解决的问题**：重复压缩后仍保留图片的会话，其 token 使用现在受到同一预算约束。
- **官方来源**：[0.150.1 发布说明](https://github.com/openai/codex/releases/tag/rust-v0.150.1)、[修复 PR #41003](https://github.com/openai/codex/pull/41003)。

## 兼容性、迁移与已知限制

- 官方 `0.150.0` 与 `0.150.1` 发布说明未列出 breaking changes（破坏性变更）或必须执行的迁移步骤。
- **行为变化**：不受信任项目的项目级 `AGENTS.md` 将被忽略；依赖这些指令时，需要先明确将项目设为受信任。
- **行为变化**：`0.150.1` 默认将 retained images 计入 compaction budget，较旧图片可能被裁剪；PR 说明显式关闭 `compaction_image_budget` 可保留旧行为。
- **限制**：Markdown 链接只有在受支持终端中显示为可点击标签，其他终端仍显示可见 URL。
- **限制**：`Interrupt` command hook 默认超时 1 秒、上限 3 秒，不适合承载长时间任务。
- **兼容性**：任务管理在旧 app-server 不支持动态工具时会回退为不带这些工具启动 thread，因此不会破坏启动，但跨任务工具不可用。

## 变更范围

- `flake.lock`：仅 `codex-cli` 节点变化；没有根级无关 input 或传递 lock 节点变化。
- `docs/nix-upgrade/codex-cli-0.150.1.md`：新增本升级报告。

## 验证证据

| 命令 | 结果 |
| --- | --- |
| `jq -e --arg input 'codex-cli' '...' flake.lock` | 升级前后均确认根 input 指向 `codex-cli` 节点，并取得完整锁定信息。 |
| `nix eval --json '.#homeConfigurations.ide.config.home.packages' --apply 'map (p: p.name)'` | 实际 Codex 包由 `codex-0.149.0` 变为 `codex-0.150.1`；`claude-code-2.1.119` 未变化。 |
| `nix flake update codex-cli` | 成功，仅更新 `codex-cli`：`36fefe1` → `18eb1ca`。 |
| `git diff -- flake.lock` | 仅 revision、`lastModified` 与 `narHash` 变化。 |
| `git diff --check` | 通过。 |
| `nix build '.#homeConfigurations.ide.activationPackage' --no-link` | 通过，成功构建 `codex-0.150.1` 与 Home Manager generation；未创建 result link。 |

构建过程中出现一条 `builtins.toFile` store reference context 警告，但命令退出码为 0，该警告未阻塞本次构建验证。

未执行 `home-manager switch`、系统 activation（激活）或 live runtime 验证，因此当前系统仍使用原有激活状态。
