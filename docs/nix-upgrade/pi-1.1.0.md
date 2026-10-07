# Pi 1.1.0 Nix input 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | `pi` → `github:lukasl-dev/pi.nix` | `pi` → `github:lukasl-dev/pi.nix` |
| 封装锁定 revision | `b900956ae011e532cd66930b83a7add1cdeb3c3f` | `2a1f1ddf5f7da2ee0c7ed3e51a2c5f5fbb70c439` |
| 封装锁定时间 | 2026-09-16 | 2026-10-07 |
| 实际应用版本 | `pi-coding-agent-0.85.1` | `pi-coding-agent-1.1.0` |
| 上游 Pi release | [`v0.85.1`](https://github.com/earendil-works/pi/releases/tag/v0.85.1) | [`v1.1.0`](https://github.com/earendil-works/pi/releases/tag/v1.1.0) |

`pi` 通过 [`lukasl-dev/pi.nix`](https://github.com/lukasl-dev/pi.nix) 的锁定包加入 `ide` profile。本次仅用 `nix flake update pi` 把封装跟踪到上游 Pi `1.1.0`，并重新求值和构建 `ide` activation package。

版本区间 `(0.85.1, 1.1.0]`，覆盖 12 个官方发布：`v0.86.0`、`v0.86.1`、`v0.87.0`、`v0.87.1`、`v0.99.0`、`v0.99.1`、`v0.99.2`、`v1.0.0`、`v1.0.1`、`v1.0.3`、`v1.0.4`、`v1.1.0`（2026-09-19 → 2026-10-07）。`v1.0.2` 仅有 git tag、无 GitHub Release 说明，其内容并入相邻版本考察。`v1.0.0` 是上游首个稳定大版本，版本序列从 `0.87.x` 直接跳到 `0.99` 再进入 `1.0`。

官方上游来源：Pi 代码仓库 [`earendil-works/pi`](https://github.com/earendil-works/pi) 的 GitHub Releases（各 tag 对应 release notes）。封装仓库只用于确认打包版本。

## 升级原因与核心新功能

### 1. TUI 默认全屏模式（1.0.0）

- **新功能**：TUI 默认以全屏（alternate screen）模式运行，会话内容独占终端视口。设置 `tuiMode: "regular"` 或传 `--tui-mode regular` 可保留终端原生 scrollback。
- **为什么需要**：官方 release notes 将其列为 1.0 的标志性默认值变化，未单独解释动机。据官方表述推断：全屏模式让 transcript 渲染与滚动行为不再与终端 scrollback 相互干扰，是长会话交互的更合理默认。
- **解决的问题**：此前 TUI 与终端 scrollback 混排，滚回历史会看到交错渲染；全屏默认消除这一歧义。偏好旧行为经一个设置即可恢复，代价极低。
- **官方来源**：[`v1.0.0` release notes](https://github.com/earendil-works/pi/releases/tag/v1.0.0)、[`settings.md#terminal-and-display`](https://github.com/earendil-works/pi/blob/v1.0.0/packages/coding-agent/docs/settings.md#terminal-and-display)。

### 2. Codemode 与内置 MCP 服务器支持（0.99.0，1.0.0 持续增强）

- **新功能**：模型可以生成 JavaScript 脚本（codemode），在单次工具调用里并行编排多个工具（如循环内批量 `read` / `bash`，只有 `console.log` 的内容进入上下文）；同时 pi 内置 MCP client，可连接任意 MCP 服务器并配合 tool search 使用。
- **为什么需要**：官方表述为 "Connect MCP servers and let models run JavaScript that calls tools in parallel"。据此推断动机：长任务中逐个串行工具调用既慢又耗上下文，codemode 把"批量读文件、过滤、聚合"这类机械工作交给脚本执行，只把结论带回对话；MCP 接入则让 pi 能直接使用生态内现成的工具服务器。
- **解决的问题**：大批量文件分析类任务此前必须逐条工具往返，上下文成本高、耗时长；MCP 生态的工具此前无法直接挂到 pi。
- **实际收益**：升级后模型可自主选择 codemode 工具并行处理大输出场景，显著降低上下文膨胀。
- **官方来源**：[`v0.99.0` release notes](https://github.com/earendil-works/pi/releases/tag/v0.99.0)、[`mcp.md`](https://github.com/earendil-works/pi/blob/v0.99.0/packages/coding-agent/docs/mcp.md)、[`cli.md#enable-codemode`](https://github.com/earendil-works/pi/blob/v0.99.0/packages/coding-agent/docs/cli.md#enable-codemode)、[`codemode.md`](https://github.com/earendil-works/pi/blob/v1.0.0/packages/coding-agent/docs/codemode.md)。

### 3. Codemode 精简与自愈错误（1.0.0）

- **新功能**：开启 codemode 后系统提示词 token 减少约 40%（默认工具 + codemode 激活时，GPT-5.6 请求从约 5300 降至约 3300 token）；codemode 脚本报错会指出恢复方式（如拼错工具名时给出接近的候选名 `tools.Bash` → `tools.bash`）。
- **为什么需要**：官方明确给出了 token 数字与动机（"Codemode costs far fewer prompt tokens"、"errors that tell the model how to recover"）。
- **解决的问题**：codemode 的采用成本——描述 token 占用与脚本试错——在 1.0.0 被显著降低，让 0.99.0 引入的 codemode 更实用。
- **官方来源**：[`v1.0.0` release notes](https://github.com/earendil-works/pi/releases/tag/v1.0.0)。

### 4. 系统主题：颜色默认跟随终端调色板（0.99.0）

- **新功能**：pi 的配色默认来自终端自身的调色板，自动匹配终端主题，不再需要为暗/亮主题分别调整 pi 主题。
- **为什么需要**：官方表述为 "Pi's colors now come from your terminal's own palette by default"。据其推断：让 pi 与用户终端深浅色外观自动一致，减少手动配主题的摩擦。
- **解决的问题**：此前 pi 用自带配色，与终端配色不协调时观感割裂；同时轻/重终端检测改为背景色优先（其次终端报告、`COLORFGBG`），检测更准确。
- **官方来源**：[`v0.99.0` release notes](https://github.com/earendil-works/pi/releases/tag/v0.99.0)、[`themes.md#use-your-terminals-colors`](https://github.com/earendil-works/pi/blob/v0.99.0/packages/coding-agent/docs/themes.md#use-your-terminals-colors)。

### 5. ChatGPT 订阅登录与 Radius 一站登录（0.99.0 / 1.0.0）

- **新功能**：`/login openai` 支持 Sign in with ChatGPT，用 ChatGPT 订阅直接驱动 OpenAI provider（旧 OpenAI Codex provider 更名为 "OpenAI Codex (legacy)"）；`/login` 顶层面板新增 Sign in with Radius 并可在登录后顺手配置 Radius MCP server。
- **为什么需要**：官方未展开动机。据其表述推断：让持 ChatGPT/Codex 订阅的用户免维护 API key，复用订阅额度；Radius 登录集成 MCP 则减少多步手工配置。
- **解决的问题**：订阅用户此前无法直接把订阅用于 pi 的 OpenAI provider。
- **官方来源**：[`v0.99.0` release notes](https://github.com/earendil-works/pi/releases/tag/v0.99.0)、[`v1.0.0` release notes](https://github.com/earendil-works/pi/releases/tag/v1.0.0)、[`providers.md#authenticate-interactively`](https://github.com/earendil-works/pi/blob/v0.99.0/packages/coding-agent/docs/providers.md#authenticate-interactively)。

### 6. Prompt cache warming（0.86.0）

- **新功能**：长工具运行期间及可选的空闲时段，通过成本感知的刷新保住有价值的 prompt cache，避免 cache 失效后的大额重算费用。
- **为什么需要**：官方表述为 "Keep valuable prompt caches alive during long tool runs and optionally while idle using cost-aware refreshes"。据其推断：长任务中 cache 过期会造成下一轮请求全价重读上下文，warming 用小额请求换取 cache 命中，净成本更低。
- **解决的问题**：长会话 + 长工具运行场景的费用下降。
- **官方来源**：[`v0.86.0` release notes](https://github.com/earendil-works/pi/releases/tag/v0.86.0)、[`settings.md#cache-warming`](https://github.com/earendil-works/pi/blob/v0.86.0/packages/coding-agent/docs/settings.md#cache-warming)。

### 7. 工具过滤增强：通配符、`--no-mcp` 与 `+name`/`-name`（1.0.4 / 1.1.0）

- **新功能**：`--tools` / `--exclude-tools` 接受 `mcp__radius__*` 这类 `*` 模式；`--tools` 默认保留 MCP 工具；`--no-mcp` 单次运行关闭 MCP；`--tools` 支持 `pi -t +codemode,-write` 增量式调整默认工具集而不是整体替换。
- **为什么需要**：官方表述为更精细的 loadout 控制。据此推断：工具集日益丰富（内置 + MCP），整体替换式过滤难以表达"默认集合加一点减一点"的意图。
- **解决的问题**：此前要么全量列工具名，要么失去 MCP 工具；现在可按命名空间保留单个 MCP server 的工具。
- **官方来源**：[`v1.0.4` release notes](https://github.com/earendil-works/pi/releases/tag/v1.0.4)、[`v1.1.0` release notes](https://github.com/earendil-works/pi/releases/tag/v1.1.0)、[`cli.md#tools`](https://github.com/earendil-works/pi/blob/v1.1.0/packages/coding-agent/docs/cli.md#tools)。

### 8. OSC 7501 程序状态上报（1.1.0）

- **新功能**：支持的终端与 agent 仪表盘可以通过 OSC 7501 转义序列感知 pi 当前状态（工作中 / 等待对话框或登录 / 完成 / 失败）。
- **为什么需要**：官方表述为 "terminals and agent dashboards that support OSC 7501 see whether Pi is working…"。据此推断：在多 agent 终端复用器（如 herdr）场景下，宿主能无侵入地展示每个 agent 的忙/闲状态。
- **解决的问题**：宿主此前只能靠轮询或解析 UI 判断 agent 状态。
- **官方来源**：[`v1.1.0` release notes](https://github.com/earendil-works/pi/releases/tag/v1.1.0)、[`terminal-setup.md#program-status`](https://github.com/earendil-works/pi/blob/v1.1.0/packages/coding-agent/docs/terminal-setup.md#program-status)。

### 9. 官方 Nix flake（1.0.1）

- **新功能**：上游 pi 自带官方 flake：`nix run github:earendil-works/pi/stable` 直接运行最新发布版。
- **为什么需要**：官方 quickstart 提供的安装路径。据此推断：降低 Nix 用户安装门槛；对本仓库而言，未来若想切换到上游官方 flake 或对比版本，多了一条受支持的来源（当前继续用 `lukasl-dev/pi.nix` 打包，不受影响）。
- **官方来源**：[`v1.0.1` release notes](https://github.com/earendil-works/pi/releases/tag/v1.0.1)、[`quickstart.md#1-install-pi`](https://github.com/earendil-works/pi/blob/v1.0.1/packages/coding-agent/docs/quickstart.md#1-install-pi)。

### 10. 新模型与启动性能（0.86.1 / 0.87.1 / 0.99.1 / 1.1.0）

- **新功能**：
  - Claude Opus 5.5（adaptive thinking、1M 上下文，含 GitHub Copilot 渠道，v0.87.1）；GPT-6 Sol / GPT-6 Luna（OpenAI 与 Copilot 渠道，v0.87.1）；GPT-6.1 Sol 并成为 OpenAI Codex 默认模型（v0.99.1）；xAI 新会话默认 Grok 4.7（v0.87.1）；Claude Haiku 5.5（v1.1.0）；GPT-6 Luna 作为分类器模型（Decisions API，v1.1.0）。
  - 启动性能：Node persistent compile cache 在 CLI 运行时加载前启用，重复启动耗时降低（v0.86.1）。
- **为什么需要**：官方 release notes 均注明"通过既有 provider 即可使用"；启动加速是明确的功能说明。模型可用性属常规上游跟进。
- **官方来源**：[`v0.87.1` release notes](https://github.com/earendil-works/pi/releases/tag/v0.87.1)、[`v0.99.1` release notes](https://github.com/earendil-works/pi/releases/tag/v0.99.1)、[`v1.1.0` release notes](https://github.com/earendil-works/pi/releases/tag/v1.1.0)、[`v0.86.1` release notes](https://github.com/earendil-works/pi/releases/tag/v0.86.1)。

## 重要修复（稳定性 / 正确性 / 安全）

以下来自各版本 Fixed 部分，选取影响实际使用与安全性的条目：

- **依赖漏洞 pin（1.0.1，安全）**：直接依赖 pin `brace-expansion` 5.0.12，修复三 GHSA 通报（GHSA-q2hr-2g5m-vwhr、GHSA-qhr7-859c-m2p7、GHSA-6j4f-fj2g-mc7p）（[#10288](https://github.com/earendil-works/pi/issues/10288)）。
- **codemode 循环输出 OOM（1.0.1）**：循环 `console.log` 的脚本可使 pi 内存耗尽崩溃；现以 16 Mi 字符 / 100 000 条目为上限并让脚本失败（[#10283](https://github.com/earendil-works/pi/issues/10283)）。
- **MCP OAuth 安全（1.0.0）**：拒绝 `iss` 参数指向别的授权服务器的授权响应，在换取 token 前校验（RFC 9207）；空 scope / `null` 可选字段导致登录失败修复；`insufficient_scope` 重新登录保留既有 scope（[#10266](https://github.com/earendil-works/pi/issues/10266)）。1.0.4 进一步修复 OIDC client 注册服务器上 `invalid_redirect_uri` 登录失败（[#10493](https://github.com/earendil-works/pi/issues/10493)）。
- **`--provider` 无 `--model` 静默忽略修复（1.0.0）**：此前会静默用其他 provider 的默认模型运行，现在报错退出（[#10236](https://github.com/earendil-works/pi/issues/10236)）。
- **transcript 内存减半（1.0.0)**：用户消息每行渲染从双份全宽副本降为单份，输出不变。
- **"Selected model is at capacity" 不再终止 turn（1.0.1）**：改为可重试（[#10278](https://github.com/earendil-works/pi/issues/10278)）。
- **Kitty / Ghostty / WezTerm / Warp 图片渲染（1.0.1 / 1.0.4）**：扩展经 `Image` 渲染的 JPEG/GIF/WebP 不显示、全屏 Kitty 图片在 WezTerm 滚动后塌陷为单行均修复（[#10292](https://github.com/earendil-works/pi/issues/10292)、[#10319](https://github.com/earendil-works/pi/issues/10319)）。
- **终端图像语法高亮修复杂色（1.0.4）**：围栏代码块中多行字符串/注释首行后失去颜色（[#10143](https://github.com/earendil-works/pi/issues/10143)）。
- **WSL 剪贴板（0.86.1）**：无 WSLg 的容器 / WSL 环境恢复 OSC 52 fallback，并新增经过验证的 WSL Windows 剪贴板后端（[#9688](https://github.com/earendil-works/pi/issues/9688)）。
- **z.ai 上下文超限识别（0.86.1）**：`Prompt too long` 此前不被识别为上下文溢出（[#9805](https://github.com/earendil-works/pi/issues/9805)）。
- **managed 安装不再堆积旧版本（1.1.0）**：`pi update` 只保留新版本 + 更新前一个版本（[#10392](https://github.com/earendil-works/pi/issues/10392)）。
- **standalone 二进制不再吞入 cwd 的 `.env`（1.1.0，安全）**：`.env` / `.env.local` / `.env.development` 此前被加载进 pi 环境（[#10473](https://github.com/earendil-works/pi/issues/10473)）。
- **复杂代码块语法高亮（1.0.4）**与 codemode `searchTools()` 等未标记 async 导致序列化为 `{}`（[#10555](https://github.com/earendil-works/pi/issues/10555)，1.1.0）。

## 兼容性

- **TUI 默认全屏（1.0.0，默认值变更）**：`tuiMode` 默认变为 fullscreen。若需保留终端原生 scrollback，在 settings 设 `tuiMode: "regular"` 或运行时用 `--tui-mode regular`。这是本次升级对日常交互影响最大的一处默认行为变化。
- **Azure provider 重命名（1.0.3，breaking）**：`azure-openai-responses` 改名为 `azure`。使用 Azure 的用户需改 `auth.json` provider key（或重新 `/login`）、`models.json`、settings 中 `defaultProvider` / `enabledModels` / `modelThinkingLevels`；旧 provider 的会话恢复时回退到其他模型且不复用 prompt cache。`AZURE_OPENAI_*` 环境变量不变。本环境未配置 Azure provider，无实际影响。来源：[v1.0.3 release notes](https://github.com/earendil-works/pi/releases/tag/v1.0.3)。
- **自定义 provider / 扩展 API（0.86.0 / 0.87.0，breaking）**：pi-ai 流式 API 的 streams 输入从 `Context` 改为归一化 `TranscriptContext`（自定义 provider 需用 `getCurrentSystemPrompt()` / `getCurrentTools()` 读上下文）；`ToolCall.arguments` 与 `ToolResultMessage.details` 限定为 JSON 兼容值；`user_bash` 失败即中止（fail-closed）；移除 `shouldStopAfterTurn`（改用 `finishTurn` 返回 `{ action: "end" }`）；`ContextEditEntry` 加入 `SessionEntry` union。**对本机自定义扩展（如 `pi-background-tasks` fork）构成升级风险，需在升级后实际运行一次验证。**
- **内置扩展与工具改名为 `builtin:<name>`（0.99.0）**：错误、诊断、RPC 源信息中的名字从 `<inline:name>` / `<builtin:name>` 统一为 `builtin:<name>`；`--no-extensions` 现在连内置扩展（含 llama.cpp provider）也禁用，显式加载用 `-e builtin:<name>`。
- **MCP OAuth 凭据存储方式（1.0.0）**：改为按 server name + URL 存储，同名 URL 的多个 server 可用不同账号登录；原按 URL 存储的凭据迁移到第一个使用它的 server。OAuth 属性配置结构（`oauth.clientName`、`oauth.authServerMetadataUrl`、`oauth.clientRegistration`、`auth.provider`）为新增可选能力，不迁移不破坏。
- **无迁移要求的常规变化**：`v0.99.x` 起 codemode/MCP/Sign in with ChatGPT 均为可选功能；模型 catalog、主题色仅影响新会话默认值。`PI_DASHBOARD_NO_MDNS` 与 `PI_BG_RUNTIME_ROOT` 两个自定义环境变量未出现在官方变更说明中，无证据表明受影响，升级后首启建议观察确认。

## 变更范围

- `flake.lock`：仅 `pi` node 自身的 `lastModified` / `narHash` / `rev` 三个字段变化（`b900956` → `2a1f1dd`），共 3 行增 3 行减；未触及任何无关根 input 或传递依赖节点。
- 无 `flake.nix` 或其他文件改动。

本次变化的 lock 节点：

```text
pi/locked.lastModified: 1789594051 -> 1791414984
pi/locked.narHash:      sha256-Tog4wJ0fhcy08bwx+KA537GJY0f/X1lyz+n98YQaFws=
                        -> sha256-1b10xGX9RH2uwPbWC4ZKUPN40LMbRNXdO6mexnU8rNk=
pi/locked.rev:          b900956ae011e532cd66930b83a7add1cdeb3c3f
                        -> 2a1f1ddf5f7da2ee0c7ed3e51a2c5f5fbb70c439
```

## 验证证据

已执行：

```text
mkdir -p /tmp/.age
jq -e --arg input "pi" '.nodes.root.inputs[$input] as $node | {input, node, locked: .nodes[$node].locked}' flake.lock   # 升级前锁定基线
nix eval --json '.#homeConfigurations.ide.config.home.packages' \
  --apply 'map (p: p.name + "-" + (p.version or "?"))' \
  | jq -r '.[] | select(test("coding-agent"; "i"))'                                                                    # 升级前版本
nix flake update pi
git diff -- flake.lock
git diff --check
nix build '.#homeConfigurations.ide.activationPackage' --no-link
nix build '.#homeConfigurations.ide.activationPackage' --no-link --print-out-paths
# 构建后复跑版本查询
nix eval --json '.#homeConfigurations.ide.config.home.packages' \
  --apply 'map (p: p.name + "-" + (p.version or "?"))' \
  | jq -r '.[] | select(test("coding-agent"; "i"))'
```

结果：

- 升级前版本查询：`pi-coding-agent-0.85.1-0.85.1`；升级后：`pi-coding-agent-1.1.0-1.1.0`。
- `git diff -- flake.lock`：仅 `pi` 节点 3 字段变化，`git diff --check` 通过，无空白错误。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` 成功构建，实际构建 derivation 包括 `pi-coding-agent-1.1.0` 与其 npm deps fetch（`-earendil-works-pi-coding-agent-install-1.1.0-sources`）。
- activation package 输出路径：`/nix/store/mrbvngqim4yi21fyxr304x9xx913422y-home-manager-generation`。
- 构建后版本复核仍为 `pi-coding-agent-1.1.0-1.1.0`。

未执行：`home-manager switch`、`darwin-rebuild switch`、`pi` 实际启动 / provider 登录 / 扩展回归（含 `pi-background-tasks`、`PI_DASHBOARD_NO_MDNS`、`PI_BG_RUNTIME_ROOT` 行为观察）等 live 验证。本次只构建 `ide` profile（当前系统 `aarch64-darwin`），不修改 `~/.pi/agent` 运行时配置或 provider 凭据。
