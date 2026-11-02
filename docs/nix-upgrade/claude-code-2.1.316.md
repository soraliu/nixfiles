# Claude Code 2.1.316 Nix input 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | `claude-code` → `github:sadjow/claude-code-nix` | 同左 |
| 锁定 revision | `7a91b64f9378dcff2180dc35b9ba033754d93b0a` | `b89e273e45ef0ea122e3410f55dd7a102e71f453` |
| 锁定时间 | 2026-10-11 | 2026-10-31 |
| 实际应用版本 | `claude-code-2.1.296` | `claude-code-2.1.316` |
| 上游项目 | [`anthropics/claude-code`](https://github.com/anthropics/claude-code) | 同左 |

本仓库消费点：`home/modules/ai/cc/default.nix`（`claude-code.packages.${system}.default`），ide 系与 clawbot 两个 profile 均安装。

版本区间覆盖 `(2.1.296, 2.1.316]`，即官方 CHANGELOG 中 2.1.299 ~ 2.1.316 的全部条目（2.1.297、2.1.298、2.1.313、2.1.315 未发布，CHANGELOG 无对应章节）。

## 升级原因与核心新功能

### 1. 终端 idle compaction（2.1.303 区间引入）

- **新功能**：200K+ token 会话空闲约 54 分钟后、1 小时 prompt cache 过期前自动压缩，下一条消息不再全量重处理；`CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS` 改 200K 门槛，settings.json `"idleCompaction": false` 关闭（均需 v2.1.290+）；`/config` 增加 `Idle compaction` 行。
- **为什么需要**：官方未展开动机。据推断：Pro/Max 按用量计费后，cache 过期导致的大会话重处理成本凸显，空闲压缩直接省钱省时。
- **解决的问题**：长会话挂起后回来第一条消息延迟与 token 消耗激增。
- **官方来源**：[CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) 2.1.303–2.1.305 段（`Added idle compaction in the terminal…`）。

### 2. 工作目录边界写保护（2.1.314）

- **新功能**：`permissions.blockWritesOutsideWorkingDirectories` —— 任意权限模式下 Write / Edit / NotebookEdit 拒绝工作目录之外的路径。
- **为什么需要**：官方未说明动机。据推断：把「越工作区写文件」从权限协商升级为硬边界，堵 `--restricted` 类会话的越界写。
- **解决的问题**：此前越界写依赖 permission rule / hook 拦截，默认模式下存在绕过面。
- **官方来源**：[CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) 2.1.314 首条。

### 3. 子代理与模型控制（2.1.316）

- **新功能**：`CLAUDE_CODE_SUBAGENT_EFFORT` —— 未显式指定时子代理的 effort 档位，不再继承主会话；`CLAUDE_CODE_DISABLE_ULTRATHINK` 关闭 `ultrathink` 关键词。
- **为什么需要**：官方未说明动机。据推断：子代理常做机械任务，全档 effort 继承造成浪费；ultrathink 误触发成本高（长思考）。
- **解决的问题**：子代理成本控制；关键词误触发深思考。
- **官方来源**：[CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) 2.1.316 前两条。

### 4. 组织 effort 上限自动降档（2.1.314 修复）

- **新功能/修复**：组织管理员封顶模型 effort 时，会话不再以 "Invalid effort level" 连续失败 —— 自动降档、重试并明示所用档位。
- **解决的问题**：企业管控环境下会话直接不可用。
- **官方来源**：同上 2.1.314 段（`Fixed sessions failing turn after turn with "Invalid effort level"…`）。

### 5. 关键正确性修复（本区间最重要的 Fixed）

- **2.1.296 回归修复**：cloud/headless 会话在重启恢复时若新消息恰好到达，已批准的工具调用可能执行两次（2.1.305 段 `Fixed a regression in 2.1.296…`）—— 对无人值守/SDK 场景是正确性级别的修复。
- **shell 残留进程修复（2.1.316）**：macOS/Linux 上凭据被拒或 cloud 会话归档导致 Claude Code 自行退出时，此前会留下运行中的 shell 命令。
- **`claude -p` 退出码（2.1.314）**：启动失败此前 exit 0 且无输出，现打印错误并 exit 1 —— 对脚本化消费方是接口级修复。
- **文件编码（2.1.30x）**：Write 不再静默把 Windows-1252 / Shift-JIS / GBK / UTF-16BE 转 UTF-8（现拒绝）；Read 修复 UTF-16LE BOM 文件乱码。
- **sandbox 越界（2.1.30x）**：macOS 沙箱内经符号链接读写 denied 路径的逃逸被堵。
- **CJK/emoji 渲染**：混排换行丢尾行、窄列空行等长期痛点多项修复。
- **官方来源**：[CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) 对应版本段。

## 兼容性

- **Breaking：Opus 4.8 fast mode 将于 2026-11-30 移除（2.1.316）**：2026-10-30 起标记 deprecated；移除后请求直接报错且**不回退**到标准 Opus 4.8，需迁移 Opus 5.5。本仓库未显式配置 fast mode（模块只装包），无直接影响；如有 `--fast` 习惯用法需在 11 月底前迁移。
- **MCP allow 规则收窄**：`mcp__a` 不再匹配名为 `a__b` 或 `a_` 的 server；含 `__` 的 server 需写 `mcp__<完整规范名>__*`（2.1.30x Changed 段）。本仓库 `~/.claude.json` 侧如有按前缀写的 allow 规则需自查（nix 不管理该文件）。
- **skill/command 文件名过滤**：名字含隐藏字符、方向控制符、`<`/`>` 的不再被加载，直到改名（2.1.30x Changed 段）。
- **MCP 协议默认协商 2026-07-28**（cloud/self-hosted runner 会话，`MCP_PROTOCOL_NEGOTIATION=legacy` 可退回）。
- **连接器代理不再跟随 HTTP 重定向**（claude.ai connector proxy 与 Anthropic 托管 MCP；connector 自身 server 不受影响）。
- 本仓库 `home/modules/ai/cc` 仅安装包、不注入任何 settings.json / managed 配置，上述迁移项均无 nix 侧动作。

## 变更范围

- `flake.lock`：`claude-code` 节点（rev / narHash / lastModified，共 4 行），无传递依赖节点变化（`nixpkgs.follows = "nixpkgs-unstable"`）。
- `docs/nix-upgrade/claude-code-2.1.316.md`：本报告。
- 无 Nix 表达式改动。

## 验证证据

- `nix eval --json '.#homeConfigurations.ide.config.home.packages'` → 更新前 `claude-code-2.1.296`，更新后 `claude-code-2.1.316`；clawbot 同。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` → 构建通过。
- `nix build '.#homeConfigurations.clawbot.activationPackage' --no-link` → 构建通过。
- `git diff --check` 通过；lock 节点总数 34 → 34，仅目标 input 变化。
- 未执行 `switch` / 激活操作：本机生效需用户自行 `switch-darwin`。
