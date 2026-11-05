# omp (oh-my-pi) 18.13.3 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| 载体 | `nixpkgs-unstable` → `github:nixos/nixpkgs/nixos-unstable`（omp 非独立 flake input，包为 `unstablePkgs.omp`） | 同左 |
| 锁定 revision | `55bfb4d7437bd4e09ab7cba58a43bd68eb310044`（2026-10-14） | `1c89083e451e891152365b799595cf7790a43325`（2026-10-30） |
| 实际应用版本 | `omp` 18.10.4 | `omp` 18.13.3 |
| 上游项目 | [`can1357/oh-my-pi`](https://github.com/can1357/oh-my-pi)，changelog 指向各 tag | 同左 |

本仓库消费点：`home/modules/ai/omp/default.nix` —— `home.packages` 装 argv[0] wrapper（`exec -a omp` 直跑 `unstablePkgs.omp` 的 bun+cli.js，herdr 进程识别用）、`unstablePkgs.omp` 两个 fetchFromGitHub 插件（omp-session-prs、omp-editor-stash）、config.yml sops merge activation。ide 系与 clawbot 两个 profile 均安装。

版本区间覆盖 `(18.10.4, 18.13.3]`：18.10.x 之后共 15 个发布（18.11.0 ~ 18.13.3），聚合 monorepo changelog 数百条，本文只保留改变实际使用方式的内容。

## 升级原因与核心新功能

### 1. composer 在工具审批挂起期间保持可用（18.11.0 + 18.11.3）

- **新功能**：审批等待时直接输入消息即「拒绝并转向」—— agent 知道为何被拒；审批提示压缩为一行（`Ctrl+O` 展开详情，[#15642](https://github.com/can1357/oh-my-pi/pull/15642)）；18.11.3 提供三选一：Approve / Approve `<tool>` for this session / Deny。
- **为什么需要**：官方未展开动机。据推断：审批阻塞整个输入通道是交互瓶颈，拒绝时携带理由比裸 deny 信息量大。
- **解决的问题**：等待审批时不能继续打字；裸 deny 后 agent 不知原因反复尝试。
- **官方来源**：[Release v18.11.0](https://github.com/can1357/oh-my-pi/releases/tag/v18.11.0)、[Release v18.11.3](https://github.com/can1357/oh-my-pi/releases/tag/v18.11.3)。

### 2. hashline 编辑系统修复（18.11.0–18.13.2，本仓库高频路径）

- **新功能/修复**：`read`/`grep` 按列截断的行尾静默丢失导致 hashline 编辑错位 —— 现拒绝编辑直到 `:raw` 全行读（18.11.0 [#15649](https://github.com/can1357/oh-my-pi/issues/15649)）；`REM` 隐藏路径恢复警告（18.11.3 [#15957](https://github.com/can1357/oh-my-pi/issues/15957)）；stale-tag 恢复路径的 seen-line 守卫（18.13.2 [#17033](https://github.com/can1357/oh-my-pi/pull/17033)）；apply-patch 要求上下文匹配并支持 move-only 段（18.13.2 [#17184](https://github.com/can1357/oh-my-pi/pull/17184)）；edit 移动保住可执行位（18.12.0 [#16042](https://github.com/can1357/oh-my-pi/pull/16042)）。
- **解决的问题**：编辑工具的静默数据损坏类 —— 本仓库日常以 omp 跑代码任务，直接受益。
- **官方来源**：对应各 release 页 Fixed 段。

### 3. Ask-and-remember 审批模式与受限目录（18.12.3 + 18.13.1）

- **新功能**：`tools.approvalMode: always-ask-cached` —— 文件读取前也询问，且记住「本文件夹/本文件」的授权（本会话或跨会话，`approval-cache.db`）；`/forget-approvals` 清空记录（[#16049](https://github.com/can1357/oh-my-pi/pull/16049)）；`tools.restrictedFolders` —— 列表内目录的一切操作在**任何审批模式（含 yolo）**下都强制显式 Approve/Deny，任何记忆授权、会话授权、ACP "Always allow" 均不覆盖（18.13.1 [#16049](https://github.com/can1357/oh-my-pi/pull/16049)）。
- **为什么需要**：官方未展开动机。据推断：高频授权记忆降低打断率，同时给敏感目录留硬边界。
- **官方来源**：[Release v18.12.3](https://github.com/can1357/oh-my-pi/releases/tag/v18.12.3)、[Release v18.13.1](https://github.com/can1357/oh-my-pi/releases/tag/v18.13.1)。

### 4. 请求压缩与连接预热（18.12.0）

- **新功能**：Anthropic 官方 API gzip 请求体；GitHub Copilot zstd（上传体积约降 60–75%）；`PI_REQUEST_COMPRESSION=0` 统一关闭（替代原 `PI_CODEX_ZSTD`）；连接预热扩展到全部内置 provider，下一 turn 免连接握手（[#16086](https://github.com/can1357/oh-my-pi/pull/16086)、[#16044](https://github.com/can1357/oh-my-pi/pull/16044)）。
- **解决的问题**：慢上行链路下长会话首字延迟；每 turn 的 TLS 握手开销。
- **官方来源**：[Release v18.12.0](https://github.com/can1357/oh-my-pi/releases/tag/v18.12.0)。

### 5. `/seance` 只读咨询保存的会话（18.11.3）

- **新功能**：就地只读咨询一个保存的 session（不 resume、不复制工件），可选模型，支持追问（[#15036](https://github.com/can1357/oh-my-pi/pull/15036)）。
- **解决的问题**：想查旧会话里的结论又不想污染/恢复它。
- **官方来源**：[Release v18.11.3](https://github.com/can1357/oh-my-pi/releases/tag/v18.11.3)。

### 6. 稳定性修复精选（影响本仓库使用面）

- **压缩可靠性**：chat-completions 上下文估算不再计入被丢弃的 past thinking，修复远早于阈值的误压缩（18.13.3 [#15797](https://github.com/can1357/oh-my-pi/issues/15797)、[#17231](https://github.com/can1357/oh-my-pi/pull/17231)）；原生远程压缩 preflight 不再把 JSON 转义体积当文本算（18.11.0 [#15712](https://github.com/can1357/oh-my-pi/pull/15712)）。
- **后台任务唤醒**：一次 Esc 不再永久杀掉会话对自身后台 job 结果的唤醒（18.13.3 [#17243](https://github.com/can1357/oh-my-pi/pull/17243)）。
- **MCP server 指令序稳定**：系统提示的 MCP 段按 server 名排序，晚连/重连不再重排导致 prompt cache 重写（18.11.0 [#15705](https://github.com/can1357/oh-my-pi/issues/15705)）。
- **`!` 命令交互修复**：zsh/fish 下 `!` 命令等交互提示不再永久挂起（18.13.3 [#17210](https://github.com/can1357/oh-my-pi/issues/17210)）。
- **`omp commit` 尊重 `commit.gpgsign`**：签名失败时 HEAD 不动（18.11.0 [#14810](https://github.com/can1357/oh-my-pi/issues/14810)）。
- **SIGTERM 恢复提示**：中断后终端归还时打印 `omp --resume <id>`（18.13.2 [#17119](https://github.com/can1357/oh-my-pi/pull/17119)）—— herdr/多路复用器场景直接受益。
- **managed-skills root 符号链接接受**：`~/.omp/agent/managed-skills` 是链接的部署形态不再被拒（18.13.3 [#17201](https://github.com/can1357/oh-my-pi/pull/17201)）。

## 兼容性

- **Breaking：`PI_CODEX_ZSTD` 被 `PI_REQUEST_COMPRESSION` 取代**（18.12.0 [#16086](https://github.com/can1357/oh-my-pi/pull/16086)）。本仓库 omp 模块的 wrapper 只导出 `PI_NOTIFICATIONS=off`（herdr 内），未用旧变量，无迁移动作。
- **已知限制：Bun 引擎要求 ≥1.4.4，nixpkgs 1c89083 pin 的 bun 为 1.4.2**。实测验证：`bun-1.4.2` 直跑 `omp-18.13.3` 的 `cli.js --version` 正常输出 `omp/18.13.3`（exit 0），engines 声明未构成硬门槛；本仓库 omp wrapper 即此组合（`exec -a omp ${unstablePkgs.bun} …cli.js`），与 nixpkgs 自带 wrapper 行为一致。风险：上游若在运行期以 Bun API 依赖 1.4.4 特性，可能出现局部故障 —— 观察 omp 升至要求更高时的 nixpkgs bun 跟进即可。
- **`_ompdeny` deny-list 维持现状**：已验证 18.13.3 bundle 对 `zaiToolStream` / `supportsToolSearch` / `supportsOpenAIGrammarTools` / `supportsAdditionalTools` / `supportsExplicitPromptCacheMode` 仍无识别（dist/cli.js grep 全 0），`agent-models` 模块的剥离逻辑继续需要，无需改动。
- **argv[0] wrapper 仍必要**：omp 跑 bun 上 `process.title` 不写回 kernel procargs 的行为未变（18.10.4 → 18.13.3 间无相关变更记录），herdr 识别依赖 `exec -a omp`，保留。
- **扩展 API breaking（18.11.2/18.11.3/18.13.0）**：`resolveGatewayApiKey` 签名、`ui.approve()` 三态化、`OpenAIRequestSetupModel` 必填字段 —— 均为扩展/auth-gateway 宿主 API。本仓库 omp 插件（omp-session-prs、omp-editor-stash）走 `plugin install` 事件模型（`session_start`/`session_switch`/`agent_end`），在 18.10.4→18.13.3 区间的 changelog 中未记录改名或移除；`agent_end` 事件在 18.11.0 有字段增强（`awaitingAsyncWork`）向后兼容。
- **TSP `t`（theme）verb 移除**（18.13.3 pi-tui Removed）：仅影响表面主题同步协议，本仓库不用 Tern 的 TSP 集成。

## 变更范围

- `flake.lock`：`nixpkgs-unstable` 节点（rev / narHash / lastModified，共 4 行）。
- `docs/nix-upgrade/omp-18.13.3.md`：本报告。
- unstable 通道整体推进的连带滚动（ide profile 118 包全量比对）：
  - `herdr` 0.9.3 → 0.9.5
  - `kubernetes-helm` 4.3.0 → 4.3.1
  - `lazygit` 0.66.1 → 0.66.2
  - `prometheus` 3.15.0 → 3.15.1
  - 其余 unstable 包在该区间未变版本；四个 harness 本体变化见各自报告。
- 无 Nix 表达式改动：omp 18.13.3 直接来自 nixpkgs `1c89083`（2026-10-30 unstable）。

## 验证证据

- `nix eval --raw 'github:nixos/nixpkgs/55bfb4d…#omp.version'` → `18.10.4`；`github:nixos/nixpkgs/1c89083…#omp.version` → `18.13.3`。
- `nix build 'github:nixos/nixpkgs/1c89083…#omp'` + `bin/omp --version` → `omp/18.13.3`。
- 模块实际组合：`bun-1.4.2` + `omp-18.13.3` 的 `lib/omp/packages/coding-agent/dist/cli.js --version` → `omp/18.13.3`，exit 0。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` → 构建通过；clawbot 同。
- ide profile 包列表前后 diff：仅上列 8 项变化（4 个 harness + 4 个连带滚动包）。
- `git diff --check` 通过；lock 节点总数 34 → 34。
- 未执行 `switch` / 激活操作：本机与 clawbot 需用户自行 `switch-darwin` / `switch-home` 生效。
