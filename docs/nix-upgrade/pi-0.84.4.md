# Pi 0.84.4 安装与 Nix input 更新报告

## 结果

| 项目 | 更新前 | 更新后 |
| --- | --- | --- |
| Nix input | 未安装 | `pi` → `github:lukasl-dev/pi.nix` |
| 封装锁定 revision | 无 | `15aa899740a918c89c3ed85a6a28d7c5e25b3924` |
| 实际应用版本 | 未安装 | `pi-coding-agent-0.84.4` |
| 上游 Pi release | 无 | [`v0.84.4`](https://github.com/earendil-works/pi/releases/tag/v0.84.4) |

`pi` 通过 [`lukasl-dev/pi.nix`](https://github.com/lukasl-dev/pi.nix) 的锁定包加入 `ide` profile。该封装当前支持 `aarch64-darwin`、`x86_64-darwin`、`aarch64-linux` 和 `x86_64-linux`，并通过自身的每日更新 workflow 跟踪 Pi 上游版本。

## 选择原因与更新路径

- Pi 上游明确提供 npm 包和官方安装脚本，但没有官方 Nix flake；直接使用 npm 全局安装会把版本和依赖移出 `flake.lock`。
- `lukasl-dev/pi.nix` 是非官方封装，但当前非归档、MIT 授权，主分支已同步到 `0.84.4`，并提供固定 source/npm 依赖哈希。
- 后续更新使用 `nix flake update pi`，再重新求值和构建 `ide` activation package。封装仓库的自动 workflow 负责把最新 Pi release 写入其版本文件。

## 0.84.4 核心变化

以下内容来自 Pi 官方 [`v0.84.4` release notes](https://github.com/earendil-works/pi/releases/tag/v0.84.4)：

1. **终端能力覆盖**：可以覆盖自动检测到的超链接、图像和 truecolor 能力。需要在不同终端复现一致显示行为时，这能避免检测结果不准确导致的 UI 差异；动机是根据 release 中新增的环境变量和高级设置说明作出的推断。详见 [`terminal-setup.md`](https://github.com/earendil-works/pi/blob/v0.84.4/packages/coding-agent/docs/terminal-setup.md#capability-overrides)。
2. **扩展 UI prompt 事件**：新增 `ui_prompt_start` / `ui_prompt_end`，集成方可以区分 agent 工作时间和等待 `ctx.ui` 用户输入的时间，解决了宿主集成无法准确区分这两种状态的问题。详见 [`extensions.md`](https://github.com/earendil-works/pi/blob/v0.84.4/packages/coding-agent/docs/extensions.md#ui_prompt_start--ui_prompt_end)。
3. **RPC `clear_queue`**：RPC 客户端可以读取并清除 queued steering/follow-up 消息，解决了进程集成需要主动管理消息队列时缺少清理接口的问题。详见 [`rpc.md`](https://github.com/earendil-works/pi/blob/v0.84.4/packages/coding-agent/docs/rpc.md#clear_queue)。
4. **Fullscreen 选择复制控制**：新增 `fullscreenCopyOnSelect`，可以关闭自动选择复制，并用 Ctrl+X 复制当前选择，解决 fullscreen 模式下自动复制行为不可控的问题。详见 [`settings.md`](https://github.com/earendil-works/pi/blob/v0.84.4/packages/coding-agent/docs/settings.md#ui--display)。
5. **稳定性修复**：修复无尾换行的 JSONL session 恢复后破坏下一条记录、工具结果触发自动压缩时仍先发送给 provider，以及运行中扩展消息插入 tool call/result 中间导致 provider 拒绝重放等问题。这些修复降低了会话恢复、长工具输出和扩展集成的失败概率。

## 兼容性与限制

- `v0.84.4` release notes 未声明 breaking change，也未要求迁移步骤；新增设置和 RPC 能力均为可选行为。
- Pi 上游默认不提供文件系统、进程、网络或凭据权限隔离；本次只安装包，没有启用 jail/sandbox。需要更强边界时应单独评估 [`containerization`](https://github.com/earendil-works/pi/blob/v0.84.4/packages/coding-agent/docs/containerization.md)。
- 本次只覆盖 `ide` profile，不修改 `clawbot` 或服务器 profile；没有写入 provider API key、模型或 `~/.pi/agent` 运行时配置。

## 变更范围

- `flake.nix`：新增 `pi` input，并把它传入 Home Manager shared args。
- `flake.lock`：新增 `pi` 及其 `bun2nix`、`jail-nix`、`systems`、`treefmt-nix` 等传递节点；未更新无关根 input。
- `home/modules/ai/pi/default.nix`：将 `pi.packages.${system}.coding-agent` 加入 `home.packages`。
- `home/profiles/ide.nix`：导入 Pi 安装模块。

## 验证证据

已执行：

```text
mkdir -p /tmp/.age
nix flake update pi
git diff --check
nix eval --json .#packages.aarch64-darwin.homeConfigurations.ide.config.home.packages \
  --apply 'map (p: p.name)'
nix build -L --no-link \
  .#packages.aarch64-darwin.homeConfigurations.ide.activationPackage
/nix/store/a7k4wlxkc5byj4iya4cxl0qqqva2bab2-pi-coding-agent-0.84.4/bin/pi --version
```

结果：

- `ide` 包列表包含 `pi-coding-agent-0.84.4`。
- activation package 构建成功，闭包包含 `pi-coding-agent-0.84.4`。
- Pi 二进制返回 `0.84.4`。
- `git diff --check` 通过。

未执行：`home-manager switch`、`darwin-rebuild switch`、provider 登录和真实 API/live session 验证。
