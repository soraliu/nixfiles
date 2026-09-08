# Pi 0.85.1 Nix input 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | `pi` → `github:lukasl-dev/pi.nix` | `pi` → `github:lukasl-dev/pi.nix` |
| 封装锁定 revision | `15aa899740a918c89c3ed85a6a28d7c5e25b3924` | `f41e1136297ccd039ead5131739da85d0ac4a77c` |
| 封装锁定时间 | 2026-09-01 | 2026-09-08 |
| 实际应用版本 | `pi-coding-agent-0.84.4` | `pi-coding-agent-0.85.1` |
| 上游 Pi releases | [`v0.84.4`](https://github.com/earendil-works/pi/releases/tag/v0.84.4) | [`v0.85.0`](https://github.com/earendil-works/pi/releases/tag/v0.85.0) + [`v0.85.1`](https://github.com/earendil-works/pi/releases/tag/v0.85.1) |

`pi` 通过 [`lukasl-dev/pi.nix`](https://github.com/lukasl-dev/pi.nix) 的锁定包加入 `ide` profile。本次仅用 `nix flake update pi` 把封装跟踪到上游 Pi `0.85.1`，并重新求值和构建 `ide` activation package。版本区间覆盖 `(0.84.4, 0.85.1]`，即 `0.85.0`（2026-09-04）与 `0.85.1`（2026-09-05）两个发布。

官方上游来源：Pi 代码仓库 [`earendil-works/pi`](https://github.com/earendil-works/pi) 的 [`CHANGELOG.md`](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md) 与对应 GitHub Releases。封装仓库只用于确认打包版本。

## 升级原因与核心新功能

### 1. GPT-6 Astra 支持（0.85.1）

- **新功能**：新增 GPT-6 Astra 模型，通过 OpenAI API key 和 OpenAI Codex 订阅即可使用。
- **为什么需要**：官方 release notes 仅说明可用通道，未解释动机。据其表述推断：用户可复用已有的 OpenAI API key 或 Codex 订阅直接使用更新的 GPT-6 Astra 模型，无需更换 provider 配置。
- **解决的问题**：扩大内置 provider 的可用模型范围，让 OpenAI 渠道用户能直接选到该模型。
- **官方来源**：[`v0.85.1` release notes](https://github.com/earendil-works/pi/releases/tag/v0.85.1)、[`providers.md#api-keys`](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/docs/providers.md#api-keys) 与 [`providers.md#openai-codex`](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/docs/providers.md#openai-codex)。

### 2. 持久化 Claude thinking effort（0.85.0）

- **新功能**：受支持的 Anthropic transports 保留每轮的 thinking effort（思考强度），并在出现 signed-thinking 不匹配时安全恢复。
- **为什么需要**：官方描述了"安全恢复"的行为，未展开动机。据其表述推断：此前 signed-thinking 不匹配可能导致 effort 丢失或请求失败，此功能确保每轮 effort 配置在恢复后仍被保留。
- **解决的问题**：避免 Anthropic provider 在 thinking 签名异常时丢失用户已设定的思考强度，提高长会话/重放场景下的稳定性。
- **官方来源**：[`v0.85.0` release notes](https://github.com/earendil-works/pi/releases/tag/v0.85.0)、[`models.md#model-configuration`](https://github.com/earendil-works/pi/blob/v0.85.0/packages/coding-agent/docs/models.md#model-configuration)。

### 3. 可恢复的内存会话（Restorable in-memory sessions，0.85.0）

- **新功能**：新增 `SessionManager.inMemory()`，通过 SDK 恢复外部存储的 session 条目。
- **为什么需要**：官方表述为"Resume externally stored session entries through the SDK"，未解释动机。据其表述推断：让外部系统把自己管理的会话历史注入 pi 恢复流程，无需先把数据落盘到 pi 的默认会话目录。
- **解决的问题**：宿主集成此前缺少把外部会话存储接回 pi 的入口；现在可通过 SDK 内存会话接口恢复。
- **官方来源**：[`sdk.md#session-management`](https://github.com/earendil-works/pi/blob/v0.85.0/packages/coding-agent/docs/sdk.md#session-management)、[PR #8980](https://github.com/earendil-works/pi/pull/8980)。

### 4. 全屏 transcript 控制、嵌入式工作指示器与搜索性能（0.85.0 + 0.85.1）

- **新功能 / 改进**：
  - 全屏 transcript 滚动后出现可点击的 "Jump to latest message" 标签，配合 `tui.altScreen.bottom` 快捷键跳回最新消息（#9080）。
  - 流式工作指示器移入默认 editor 边框，颜色与 thinking 级别边框对齐；自定义 editor 可选择嵌入（#8799）。
  - 全屏 transcript 搜索在大记录上降低延迟：缓存未变搜索结果、索引 ASCII 片段、只对可见匹配做高亮（#8800）。
- **为什么需要**：官方描述为功能行为与性能改进，未解释动机。据其表述推断：长会话滚动后不易回到最新消息，加入跳转入口提升可用性；工作指示器归入边框减少视觉跳变；搜索优化让大 transcript 操作更流畅。
- **解决的问题**：全屏长会话的导航与工作状态可读性，以及搜索在高记录量下的响应延迟。
- **官方来源**：[`keybindings.md#tui-fullscreen-viewport`](https://github.com/earendil-works/pi/blob/v0.85.0/packages/coding-agent/docs/keybindings.md#tui-fullscreen-viewport)、[PR #9080](https://github.com/earendil-works/pi/pull/9080)、[PR #8799](https://github.com/earendil-works/pi/pull/8799)、[PR #8800](https://github.com/earendil-works/pi/pull/8800)。

### 5. vLLM 调度优先级与 OpenAI Responses 输出 token 上限（0.85.0）

- **新功能**：inherited OpenAI-compatible 模型设置新增 `vllmPriority`（vLLM 调度优先级）和 `supportsMaxOutputTokens`（OpenAI Responses 输出 token 上限）。
- **为什么需要**：官方以 PR 描述形式给出，未单独解释动机。据其表述推断：让自托管 vLLM 用户在 pi 中设置调度优先级，并为 OpenAI Responses 响应模型设置输出 token 上限，对接这两类服务端能力。
- **解决的问题**：此前 vLLM 调度优先级与 Responses 输出限制无法在 pi 模型设置里表达；新增字段后可按模型配置。
- **官方来源**：[PR #9004](https://github.com/earendil-works/pi/pull/9004)、[PR #8941](https://github.com/earendil-works/pi/pull/8941)。

> 说明：本仓库根 `AGENTS.md` 指向了 WSL Ubuntu vLLM 配置指南，自托管 vLLM 属于本仓库关注范围，故将此项列为核心变化。

## 重要修复（稳定性 / 正确性）

以下来自 `0.85.0` 与 `0.85.1` 的 Fixed 部分，选取影响实际使用与稳定性的条目：

- **SDK import 回归修复（0.85.1）**：0.85.0 不慎发布了内部 experimental 代码与依赖，导致 SDK import 失败。0.85.1 修复后，experimental `client` / `experimental/plugin` subpaths 与 server/client 命令改为仅通过 `pi-test.sh` 以 source 形式提供；官方支持的 local SDK 与 stdio RPC API 不变（[#9132](https://github.com/earendil-works/pi/issues/9132)）。
- **工具忽略 `ctx.cwd` 修复（0.85.0）**：`bash` / `edit` / `find` / `grep` / `ls` / `read` / `write` 工具此前忽略 `ctx.cwd`，已在正确工作目录执行（[#8627](https://github.com/earendil-works/pi/pull/8627)）。
- **skills 在 Bash 为唯一工具时不可用修复（0.85.0）**（[#8552](https://github.com/earendil-works/pi/pull/8552)）。
- **代理下 plain-HTTP provider 请求挂起修复（0.85.0）**：工具调用后的 plain-HTTP provider 请求挂起，改为用 CONNECT 隧道穿越代理（[#8134](https://github.com/earendil-works/pi/issues/8134)）。
- **GPT-5.6+ Responses prompt-cache 参数修正（0.85.1）**：长 prompt-cache 请求改用 `prompt_cache_options.ttl: "30m"`，替代旧的 `prompt_cache_retention: "24h"`。
- **会话稳定性（0.85.0）**：修复导入会话覆盖同名文件（[#8985](https://github.com/earendil-works/pi/pull/8985)）、session fork 丢失 compaction 边界（[#8990](https://github.com/earendil-works/pi/pull/8990)）、in-memory fork 在 turn 未结束时的问题（[#8937](https://github.com/earendil-works/pi/pull/8937)）。
- **branch summaries 在 reasoning 占满 2048-token 输出上限时失败修复（0.85.0）**（[#8845](https://github.com/earendil-works/pi/issues/8845)）。
- **write 工具误报计数修复（0.85.0）**：移除把 UTF-16 code-unit 计数当作 byte 计数的误导性计数（[#8979](https://github.com/earendil-works/pi/issues/8979)）。
- **RPC `abort` 误报成功修复（0.85.0）**：此前 `abort` 在进行中的 manual compaction 未取消时仍报成功（[#8920](https://github.com/earendil-works/pi/issues/8920)）。
- **managed 工具链修复（0.85.0）**：修复 Linux musl 系统上 `fd` / ripgrep 下载（[#9070](https://github.com/earendil-works/pi/pull/9070)），并去除对 GitHub Releases API 的硬依赖（[#8708](https://github.com/earendil-works/pi/pull/8708)）。

## 兼容性

- `v0.85.0` 与 `v0.85.1` 的 release notes 均未声明 breaking change，也未要求迁移步骤；新增设置、SDK 和 RPC 能力均为可选行为。
- **唯一需注意的边界**：0.85.0 误发布的 experimental `client` / `experimental/plugin` subpaths 与 server/client 命令，在 0.85.1 被移为 source-only（通过 `pi-test.sh`）。仅影响使用这些 experimental 入口的代码；官方支持的 local SDK 与 stdio RPC API 不变。若此前针对 0.85.0 的误发布入口写过代码，升级到 0.85.1 后需改用 `pi-test.sh` 或官方 API。来源：[#9132](https://github.com/earendil-works/pi/issues/9132)。
- **prompt-cache 参数变化**：GPT-5.6+ Responses 模型的长 prompt-cache 请求改用 `prompt_cache_options.ttl: "30m"`。这是 provider 侧参数调整，属正确性修复，无需用户迁移，但若自行抓包对照请求体需注意字段不同。

## 变更范围

- `flake.lock`：仅 `pi` node 自身的 `lastModified` / `narHash` / `rev` 三个字段变化（`15aa899` → `f41e113`），共 3 行增 3 行减；未触及任何无关根 input。
- 无 `flake.nix` 或其他文件改动。

本次变化的 lock 节点：

```text
pi/locked.lastModified: 1788254858 -> 1788857715
pi/locked.narHash:      sha256-DmRni2y8qjf8TueivkhiLCf6ztaF7rX3XyUa2kWGouA=
                        -> sha256-QrGCBqM2ZBH0e5g3fxTPVwX/vi5piAzm15T1JT65jbg=
pi/locked.rev:          15aa899740a918c89c3ed85a6a28d7c5e25b3924
                        -> f41e1136297ccd039ead5131739da85d0ac4a77c
```

## 验证证据

已执行：

```text
mkdir -p /tmp/.age
nix flake update pi
git diff -- flake.lock
git diff --check
nix eval --json '.#homeConfigurations.ide.config.home.packages' \
  --apply 'map (p: p.name)' \
  | jq -r '.[] | select(test("coding-agent"; "i"))'
nix build '.#homeConfigurations.ide.activationPackage' --no-link
nix build '.#homeConfigurations.ide.activationPackage' --no-link --print-out-paths
# 构建后复跑版本查询
nix eval --json '.#homeConfigurations.ide.config.home.packages' \
  --apply 'map (p: p.name)' \
  | jq -r '.[] | select(test("coding-agent"; "i"))'
```

结果：

- `git diff -- flake.lock`：仅 `pi` 节点 3 字段变化，`git diff --check` 通过。
- `homeConfigurations.ide` 包列表中 `pi-coding-agent-0.84.4` 已变为 `pi-coding-agent-0.85.1`。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` 成功构建（7 个 derivation built），包括 `pi-coding-agent-0.85.1`。
- activation package 输出路径：`/nix/store/l5hbsn1nk07w2h68bshp9kbdnfxxnck5-home-manager-generation`。
- 构建后版本复核仍为 `pi-coding-agent-0.85.1`。

未执行：`home-manager switch`、`darwin-rebuild switch`、provider 登录和真实 API / live session 验证。本次只构建 `ide` profile（当前系统 `aarch64-darwin`），不修改 `~/.pi/agent` 运行时配置或 provider 凭据。
