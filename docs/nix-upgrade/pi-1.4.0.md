# Pi 1.4.0 Nix input 升级报告

## 升级结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | `pi` → `github:earendil-works/pi/stable` | 同左 |
| 锁定 revision | `abe508e1b89912adde45528136c3221eb69acdd7` | `4a080252f06caf63a525d7873c5d94d3c23887e0` |
| 锁定时间 | 2026-10-07 | 2026-10-21 |
| 实际应用版本 | `pi-1.1.0` | `pi-1.4.0` |
| 上游项目 | [`earendil-works/pi`](https://github.com/earendil-works/pi) | 同左 |

本仓库消费点：`home/modules/ai/pi/default.nix`（`pi.packages.${system}.pi`，官方 flake v1.0.1 起）+ 两个 sessionVariable（`PI_DASHBOARD_NO_MDNS=1`、`PI_BG_RUNTIME_ROOT=$HOME/.pi`）+ `pi install npm:@plannotator/pi-extension` 幂等守卫。ide 系与 clawbot 两个 profile 均安装。

版本区间覆盖 `(1.1.0, 1.4.0]`：v1.2.0（2026-10 左右）、v1.3.0、v1.4.0 三个发布。

## 升级原因与核心新功能

### 1. 压缩与分支摘要不再因长推理失败（1.4.0）

- **新功能**：compaction 与 branch summary 改用模型自身 output limit，不再受固定摘要输出上限约束；`reserveTokens` 只控制压缩触发时机。
- **为什么需要**：此前固定 output cap 下，模型推理占满配额时摘要请求以 "generation hit the token cap" 失败（[#9512](https://github.com/earendil-works/pi/issues/9512)、[#9075](https://github.com/earendil-works/pi/issues/9075)）。
- **解决的问题**：长会话（高推理模型）压缩可靠性 —— 本仓库主力 agent 场景直接受益。
- **官方来源**：[Release v1.4.0](https://github.com/earendil-works/pi/releases/tag/v1.4.0) New Features 首条与 Fixed 段。

### 2. codemode 并发排队（1.4.0）

- **新功能**：并行脚本与进程内 subagent 的 codemode 调用排队等待空闲 worker（最长 60s），不再立即失败；`PI_CODEMODE_MAX_WORKERS` 可调高默认 2 个 worker 上限。
- **解决的问题**：[#11184](https://github.com/earendil-works/pi/issues/11184) 两个 worker 忙时 codemode 脚本直接报错。
- **官方来源**：同上 v1.4.0。

### 3. herdr 内联图像修复（1.2.0，本仓库环境直接相关）

- **新功能/修复**：1.1.0 起内联图像在 Herdr 中不渲染的问题修复（[#10774](https://github.com/earendil-works/pi/pull/10774)）。
- **官方来源**：[Release v1.2.0](https://github.com/earendil-works/pi/releases/tag/v1.2.0) Fixed 段。
- 备注：本仓库日常在 herdr 内跑 pi（worktree 工作流），此修复对实际使用面有效。

### 4. Nix 打包两层修复（1.3.0，nix 消费方直接相关）

- **修复**：① flake 构建在 provider 切换 API 时失败 —— model catalog pin 现在从最新发布目录刷新（[#10985](https://github.com/earendil-works/pi/issues/10985)）；② Nix 包把自带 Node.js 排在 PATH 首位，导致 bash 工具 shell 用 pi 的 Node 而非用户的 `node`/`npm` —— 现仅作 fallback（[#10519](https://github.com/earendil-works/pi/issues/10519)）。
- **解决的问题**：nixpkgs-unstable 推进后打包崩坏的风险面收敛；工具 shell 的 Node 环境正确性。
- **官方来源**：[Release v1.3.0](https://github.com/earendil-works/pi/releases/tag/v1.3.0) Fixed 段。

### 5. 配置 schema 发布与编辑器校验（1.2.0）

- **新功能**：`settings.json` / `models.json` / keybindings / themes 均可加 `$schema` 获得 IDE 校验与补全；schema 发布于 `https://pi.dev/schemas/*.schema.json`（[文档](https://github.com/earendil-works/pi/blob/v1.2.0/packages/coding-agent/docs/settings.md)）。
- **为什么需要**：官方未说明动机。据推断：配置面变大后，手写 JSON 的键名错误率高。
- **解决的问题**：本仓库 `agent-models` 模块 merge `~/.pi/agent/models.json`，schema 可用于校验合并产物。
- **官方来源**：[Release v1.2.0](https://github.com/earendil-works/pi/releases/tag/v1.2.0) New Features。

### 6. 模型切换清理旧思考块（1.3.0）

- **新功能**：切换模型时丢弃前一模型的 thinking 块，不再当普通文本喂给新模型（[#10995](https://github.com/earendil-works/pi/issues/10995)）—— 此前新模型会把旧模型推理当正文读、甚至学着往可见回复里写推理。
- **官方来源**：同上 v1.3.0。

## 兼容性

- **Breaking（1.2.0）：theme schema 迁移** —— theme `$schema` 引用需更新到 `https://pi.dev/schemas/theme.schema.json`，可复用颜色改定义在 `vars` 下，不支持的元数据移除；启动时加载的 theme 也会做与重载相同的校验（[#9880](https://github.com/earendil-works/pi/pull/9880)）。本仓库 nix 不管理 theme 文件；若本机 `~/.pi/agent/themes/` 有自写主题需自查。
- **Breaking（1.2.0）：扩展 API 语义** —— `before_agent_start` 也对 `pi.sendMessage(..., { triggerTurn: true })` 触发的运行触发，事件变为 `messageType` union；session busy 判定扩展到运行启动阶段，`pi.sendMessage()` 在启动中会排队而非报 "Agent is already processing"（[#10739](https://github.com/earendil-works/pi/pull/10739)）。本仓库安装的 `npm:@plannotator/pi-extension`（现役 0.27.15）由 `pi install` 运行时装载、nix 不管理版本；若该扩展用到上述 API，需按其上游适配。守卫脚本只做缺装补装，升级 pi 不重装扩展。
- **Breaking（1.3.0）：`kimi-coding` base URL 覆盖必须带 `/v1`** —— 本仓库 catalog（`secrets/.config/ai/agent-models-catalog.enc.json`）未使用 kimi provider（已核实），无影响。
- **`pi mcp list --json`**：`resources` / `resourceTemplates` 计数改为布尔 `resources: true`（1.2.0）—— 本仓库无消费该 CLI 输出的脚本。
- **已知限制**：`_ompdeny`（agent-models 模块为 omp 剥离的 pi 新 compat 键）涉及的 catalog compat 字段全部保留 pi 侧语义（pi 是 catalog 超集消费方），1.4.0 的 [Models Configuration 参考](https://github.com/earendil-works/pi/blob/v1.4.0/packages/coding-agent/docs/models-configuration.md) 与本仓库 merge 逻辑兼容（已核实 catalog 现有字段均在新参考覆盖内）。
- 本仓库 sessionVariables 两个键：`PI_DASHBOARD_NO_MDNS`、`PI_BG_RUNTIME_ROOT` 在 1.2.0–1.4.0 的 release notes 中均无改名或移除记录。

## 变更范围

- `flake.lock`：`pi` 节点（rev / narHash / lastModified，共 4 行），无传递依赖节点新增或删除（节点总数 34 → 34）。
- `docs/nix-upgrade/pi-1.4.0.md`：本报告。
- 无 Nix 表达式改动。

## 验证证据

- `nix eval --json '.#homeConfigurations.ide.config.home.packages'` → 更新前 `pi-1.1.0`，更新后 `pi-1.4.0`；clawbot 同。
- `nix build '.#homeConfigurations.ide.activationPackage' --no-link` → 构建通过。
- `nix build '.#homeConfigurations.clawbot.activationPackage' --no-link` → 构建通过。
- `git diff --check` 通过。
- catalog 无 kimi 引用：`sops -d secrets/.config/ai/agent-models-catalog.enc.json | grep -io 'kimi[a-z-]*'` → 空。
- 未执行 `switch` / 激活操作；`pi install` 幂等守卫行为不变。
