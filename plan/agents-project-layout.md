# 计划:全局 AGENTS.md 增加本地项目分布说明

## Context

全局 `~/.pi/agent/AGENTS.md` 缺少一张"本地项目地图":agent 在各会话中经常不知道公司项目、个人基础设施项目分别放在哪个目录,需要每次重新扫描或询问。本次扫描用户目录后,把极简的项目分布说明沉淀进全局 AGENTS.md。

**目标文件**:`~/.pi/agent/AGENTS.md`(经 `git rev-parse` 确认**不在任何 git 仓库内**,因此不适用「代码修改流程」的 worktree/PR 要求,直接编辑即可)。

## 已确认决策(用户拍板)

1. 覆盖范围:**全貌极简版** — 公司线（gitops-wrapper + AstroWeb3 + `~/AstroCube` 顶层独立仓库 `k3s-ops`/`gitops-infra`）+ 个人线三项 + wrapper 符号链接机制说明（含 2026-10 目录重组后的分布）
2. 插入位置:「核心原则」下,**「项目记忆」节之后、「## 常用工具」之前**
3. 不补充「项目记忆」节的 memories 记库路径(本次不动该节)
4. 本 plan 文件已由主工作区移入 worktree, 随 PR 提交入 git; 执行验证通过后无需再手动清理主工作区

## 插入内容(最终草案)

在 `~/.pi/agent/AGENTS.md` 的「- 写入时机：… → refs」条目与「## 常用工具」之间插入:

```markdown
## 本地项目分布

- `~/.nixfiles` — 本机 Nix 配置（darwin + home-manager flake）
- `~/AstroCube/gitops-wrapper` — 公司集群运维 wrapper 工作区（本身非单一仓库, 成员多为符号链接）；实体仓库：`gitops-astrocube`、`gitops-sites`、`baihong-1xtoken`（`k3s-ops`、`gitops-infra` 已于 2026-10 迁出为 `~/AstroCube` 顶层独立仓库）
- `~/AstroCube/k3s-ops` — 公司集群 ops（prod-evoxt kubeconfig 在此）；`~/AstroCube/gitops-infra` — 公司 GitOps 真源（Flux manifests）
- `~/AstroWeb3` — 公司业务代码另一条根：`gitops-modellink`、`gitops-trustpay`、`merchant-sites`、`paperclip`、`*-mono` 系列等实体仓库所在地, 被 gitops-wrapper 以符号链接引用
- `~/Github/personal-pve-next` — 本机 PVE（Proxmox VE）重建与管理, just + Ansible（`~/Github/personal-pve` 仅作历史基线）
- `~/Github/personal-k3s-ops` — 个人 k3s 集群 ops（Nebula / FRR / K3s, 含 vpn、derp 等, 2026-10 由 `~/Github/nixfiles-wrapper` 迁出为顶层独立仓库）；`~/Github/nixfiles-wrapper` — 个人运维 wrapper, 仍符号链接 `~/.nixfiles` 与公司 `~/AstroCube/k3s-ops` 等
- 区分：公司集群 ops = `~/AstroCube/k3s-ops`, 个人 = `~/Github/personal-k3s-ops`, 二者不同
```

## Files to modify

- `~/.pi/agent/AGENTS.md` — 唯一改动文件,一处插入

## Steps

- [ ] 1. 用 edit 在 `~/.pi/agent/AGENTS.md`「项目记忆」节末尾(`→ refs` 行)与 `## 常用工具` 之间插入上述「## 本地项目分布」节
- [ ] 2. 通读插入段落,确认与既有排版风格、空行节奏一致

## Verification

- `grep -n "本地项目分布" ~/.pi/agent/AGENTS.md` 确认新节存在且位于「项目记忆」与「常用工具」之间
- `head -60 ~/.pi/agent/AGENTS.md` 人工通读格式
- [ ] 3. 验证通过后删除本 plan 文件:`rm ~/.nixfiles/plan/agents-project-layout.md`
