# 清除仓库明文敏感信息（凭据 + VPS 公网 IP）

## Context

`.nixfiles` 仓库使用 sops-nix 管理 secrets。全仓扫描结论：**加密文件（`ENC[AES256...]`）全部合规，一律保留不动**；历史上 `secrets/` 目录所有 blob 也均为加密内容，仅少量明文敏感信息需要清除。

用户已拍板三个决策：

| 决策点 | 结论 |
|---|---|
| 清理范围 | **凭据 + VPS 公网 IP**（邮箱、域名、内网 IP、公司结构提及均不在本次范围） |
| 处理方式 | **变量占位符脱敏**（文档保留，敏感值参数化） |
| 历史层 | **git filter-repo 重写历史** + force push |

本文件自身不含明文字面值（涉及处一律占位描述），可随 PR 安全提交。

## 实际扫描结论（Step 2 复扫）

- 当前提交存在明文的目标文件仅 3 个：`docs/openviking/openviking-relevance-test-results.md`（5 处 X-API-Key）、`plan/hysteria2-upgrade.md`（2 处共 4 个 VPS IP）、（先前版本的）本 PLAN.md
- **历史 blob 中另有 12 个已删除文件**含 VPS IP：`docs/network/.tmp/task-5-vpn-stage*.sh`、`docs/network/data/task-1-*.txt` / `task-2-*.txt` / `task-5-*.txt`、`docs/network/jumbo-mtu-*.md`、`plan/jumbo-mtu-research.md` —— `filter-repo --replace-text` 为全历史字节替换，**天然覆盖，无需额外规则**
- 字面值清单（API key ×1 + VPS IP ×4）在执行时一律**程序化从 mirror 备份提取**（见 Step 7），本文不记录

## Steps

### 阶段一：PR 修改当前提交（常规流程）

- [x] 1. `git fetch origin --prune`；建 worktree 分支 `sanitize-plaintext-secrets`
- [x] 2. 全仓复扫确认目标清单（含发现 12 个历史文件，见上节）
- [x] 3. `docs/openviking/openviking-relevance-test-results.md`：5 处 `-H "X-API-Key: <原值>"` → `$OV_API_KEY` + 文首脱敏说明注记；`plan/hysteria2-upgrade.md`：4 个 VPS IP → `<vpn_{premium,primary,secondary,hangzhou}_ip>`（替换均程序化提取字面值）；worktree 字节级复扫零残留
- [x] 4. 本 `PLAN.md`（脱敏版）mv 进 worktree 随 PR 提交（主工作区不残留）
- [ ] 5. push 创建 PR（仅文档改动），等用户授权后 squash merge

### 阶段二：历史重写（须在 PR 合并后、用户在场确认时执行）

- [ ] 6. `git clone --mirror` 到仓库外路径做额外备份（**此备份同时是 Step 7 的字面值来源**——届时工作区明文已被阶段一替换消失）
- [ ] 7. 从 mirror 备份的程序化提取字面值生成 replace 规则文件（API key ×1 → `$OV_API_KEY`；VPS IP ×4 → `<vpn_*_ip>`），共 5 条 `literal:` 规则，替换值与阶段一 PR 完全一致
- [ ] 8. `nix shell nixpkgs#git-filter-repo` 后对主工作区执行 `git filter-repo --replace-text <规则文件> --force`，然后重新接回 remote（filter-repo 会移除 origin）并 `git push --force`

### 阶段三：收尾

- [ ] 9. 其他使用本仓库的机器：`git fetch origin && git reset --hard origin/<branch>`
- [ ] 10. 清理 worktree 与 mirror 备份

## 对 sops 加密文件的影响（已干跑验证）

> [!IMPORTANT]
> 已在临时 clone 完成全链路干跑：`secrets/` 全历史 571 个 blob 重写前后 sha **完全一致**（`--replace-text` 只字节级改写命中目标字面值的 blob，sops 密文为零命中）；重写后全历史目标字面值零匹配；HEAD 占位符正确落盘；277 个文件清单无增删。阶段二执行后复验「secrets blob 前后一致」。

## Verification

- [ ] 当前工作区字面值清单（取自 mirror 备份提取结果）`rg` 零匹配
- [ ] 历史层 `git grep` 遍历 `git rev-list --all` 全 commit 零匹配
- [ ] 重写前后 `git rev-list --objects --all -- secrets/` blob 清单 diff 为空
- [ ] GitHub 网页端 spot check：force push 后旧 commit SHA 访问应 404

## 风险与已知限度

> [!IMPORTANT]
> - filter-repo 重写后所有旧 commit hash 变化，force push 前需用户明确确认；已做 mirror 备份兜底
> - openviking 已弃用，原 API key 无需轮换；VPS IP 暴露风险由防火墙前置兜底
> - GitHub 侧被 fork / 被 PR 引用过的旧 SHA 及服务端 dangling 对象可能仍短暂可达，绝对彻底需联系 GitHub support
> - sops 加密文件零影响（见干跑验证结论）
