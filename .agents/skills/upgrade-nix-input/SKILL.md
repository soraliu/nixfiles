---
name: upgrade-nix-input
description: 升级本项目一个或多个指定的 Nix flake input，并验证受影响配置，基于上游官方发布说明总结升级后的核心新功能、升级原因和解决的问题，将报告保存到 docs/nix-upgrade。用户要求更新、升级或检查 codex、codex-cli、Claude Code、claude-code 或其他 flake input 时使用。
---

# 升级 Nix input

只更新用户点名的 input。优先使用仓库已有命令和 Nix 原生命令，不新增更新脚本。

## 识别目标

1. 读取根目录 `AGENTS.md`，遵守 branch、worktree、提交和 PR 规则。
2. 把用户名称映射到 `flake.nix` 中的真实 input 名：
   - `codex`、`codex cli` -> `codex-cli`
   - `claude`、`claude code` -> `claude-code`
3. 对其他名称，从 `flake.nix` 和 `.nodes.root.inputs` 确认真名，不猜测。

用以下命令确认目标存在，并记录更新前的锁定信息：

```bash
input="codex-cli"
jq -e --arg input "$input" \
  '.nodes.root.inputs[$input] as $node | {input: $input, node: $node, locked: .nodes[$node].locked}' \
  flake.lock
```

## 记录应用版本

不要把 flake 包装仓库的 revision 当成 Codex 或 Claude Code 的应用版本。更新前后都从实际 Home Manager 包列表记录版本：

```bash
mkdir -p /tmp/.age
nix eval --json '.#homeConfigurations.ide.config.home.packages' \
  --apply 'map (p: p.name)' \
  | jq -r '.[] | select(test("codex|claude"; "i"))'
```

升级其他 input 时，先查找它的消费模块和对应 flake output，再选择能显示实际版本的 `nix eval` 目标。

## 执行升级

一次传入所有指定 input：

```bash
nix flake update codex-cli claude-code
```

更新后统一检查：

```bash
git diff -- flake.lock
git diff --check
```

允许目标 input 自身以及它不与根 flake 共用的传递依赖发生变化。若无关的根 input 也被更新，先查明原因；无法证明属于目标依赖闭包时恢复方案，不提交扩大范围的锁文件。

若指定 input 已是最新且没有文件变化，报告“无需升级”，删除本次空 worktree，不创建空提交或 PR。

## 验证结果

对于 `codex-cli` 和 `claude-code`，至少执行：

```bash
nix build '.#homeConfigurations.ide.activationPackage' --no-link
```

构建后重跑“记录应用版本”中的查询。如果用户指定了其他系统或 profile，再构建对应 output。不要默认执行 `switch` 或其他系统激活操作。

验证失败时，保留原始错误和已确认的边界。不要仅凭 lock 更新成功声称升级可用。

## 提炼核心新功能

先用更新前后的实际应用版本确定版本区间，再查官方上游资料。遵守以下规则：

- 优先使用应用项目的官方 release notes、changelog、文档和代码仓库；flake 包装仓库只用于确认打包版本。
- 覆盖 `(旧版本, 新版本]` 内的发布内容，不只查看最新版。
- 只保留会改变实际使用方式、兼容性、安全性、稳定性或性能的内容。过滤打包维护、依赖噪音和重复描述。
- 每项分别说明“新功能”“为什么需要”“解决了什么问题”，并附直接支持该结论的官方链接。
- 发布说明没有解释动机时，把“为什么需要”明确标为推断，并说明推断依据。不要把推断写成官方结论。
- 没有值得称为核心新功能的版本时如实写“本次主要是修复或维护更新”，列出最重要的修复，不凑功能数量。
- 同时检查 breaking changes（破坏性变更）、迁移要求和已知限制。

## 生成升级报告

仅在目标 input 的 lock 确实变化且验证通过后，为每个完成升级的 input 生成一份报告；input 已是最新或验证失败时不生成：

```text
docs/nix-upgrade/{input-name}-{new-version}.md
```

- `input-name` 使用 `flake.nix` 中的真实 input 名。
- `new-version` 优先使用升级后的实际应用或包版本；无法取得时使用新锁定 revision 的前 12 位。将版本中不属于 `[A-Za-z0-9._+-]` 的字符替换为 `-`。
- 将报告与 `flake.lock` 放在同一个升级提交和 PR 中。

报告包含：

1. 升级结果：input、锁定 revision、实际应用版本的旧值和新值。
2. 升级原因和核心新功能：每项说明为什么需要、解决的问题和官方来源。
3. 兼容性：breaking changes（破坏性变更）、迁移要求和已知限制。
4. 变更范围：实际变化的文件和传递 lock 节点。
5. 验证证据：执行的命令及结果，以及未执行的激活或 live 验证。

## 提交与交付

生成升级报告后按根 `AGENTS.md` 完成提交与交付。PR 和最终回复简要说明升级结果，并提供报告路径和 PR 链接；详细内容引用报告，不重复复制。
