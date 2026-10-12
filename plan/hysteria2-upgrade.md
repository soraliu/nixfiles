# 计划: Hysteria2 升级 & 抗 UDP 封锁加固（服务端 + 客户端）

## Context

基于 2026-10 全网调研结论（GFW 自 2024-04 起可**解密 QUIC Initial 读 SNI** 做定向封锁（USENIX Security 2025）；ISP 层对长时大流量 UDP 普遍 QoS/按流惩罚；hy2 存活者的标配 = **port hopping + obfs + 保持版本最新**），对现有 Hysteria2 部署做版本升级与配置加固，缓解「经常因 UDP 传输被封锁」问题。症状为混合形态（QoS + 按流惩罚 + 定向阻断并存），故多手段叠加。

## 已拍板决策

| 决策点 | 结论 |
|---|---|
| obfs | **开 Salamander**（免疫解密式封锁；证书沿用 bing.com 自签，客户端 skip-cert-verify 不变） |
| 版本 | hysteria 2.7.1 → **2.13.0**；xray 26.2.6 → **26.3.27**（stable） |
| 范围 | **4 台** VPS（vpn_premium 103.112.1.197 / vpn_primary 45.202.255.241 / vpn_secondary 179.255.150.220 / vpn_hangzhou 47.98.202.4，全部在 `vpn_nodes` group）+ 两类客户端；vpn_premium 同时承担 tailnet DERP/relay，hy2 升级不影响其余服务（仅 restart hysteria/xray） |
| 端口池 | **UDP 20000-30000**，系统防火墙由 Ansible 管理 |
| Nix 系 profile（vpn-server/vpn-relayer） | 不动（unstable 已 2.12.3，仅同步思路待其追平） |

## 现状盘点（已侦察）

| 组件 | 位置 | 现状 |
|---|---|---|
| Ansible 服务端 | `~/Github/personal-k3s-ops` 的 `ansible/roles/vpn_server/` | hysteria 2.7.1 + xray 26.2.6；binary 从 GitHub release 下载，checksum 硬编码于 `ansible/roles/vpn_server/defaults/main.yml`（下载基址仍是旧名 `apernet/hysteria`，已改名 `HyNetworks/hysteria`） |
| 部署入口 | `ansible/playbooks/edge/vpn.yml` → group `vpn_nodes`，共 4 台（vpn_premium 103.112.1.197 / vpn_primary 45.202.255.241 / vpn_secondary 179.255.150.220 / vpn_hangzhou 47.98.202.4） | sops secrets 经 `community.sops.load_vars` 注入 |
| hysteria 配置 | `ansible/secrets.yaml`: `VPN_HYSTERIA_CONFIG_YAML` + bing.com crt/key（sops 密文） | 现有字段待执行时解密确认（无 port hopping/obfs） |
| 旁路由客户端 | `~/.nixfiles/docker/immortalwrt/`（Dockerfile + default.nix） | ImmortalWrt 24.10.4 容器 @192.168.31.2，nikki + mihomo **v1.19.27**（✅ 支持 ports/hop-interval/obfs，内核无需动）；tproxy 模式 |
| 桌面客户端 | `~/.nixfiles/home/modules/network/clash-meta/default.nix` | mihomo from unstablePkgs（同参数支持） |
| 客户端配置源 | `~/.nixfiles/secrets/.config/clash/config-whitelist.enc.yaml`（sops，桌面与旁路由共用一份） | hy2 出站节点待加字段 |
| sysctl | `roles/vpn_server/tasks/sysctl.yml` + hysteria 模块 activation | ✅ rmem/wmem 64MB 已就位 |

## Approach

### 1. Ansible role 更新（personal-k3s-ops）

- `defaults/main.yml`：
  - `vpn_server_hysteria_version: "2.13.0"` + 重新计算 arch_map checksum（执行时从 [release app/v2.13.0](https://github.com/HyNetworks/hysteria/releases/tag/app%2Fv2.13.0) assets 获取 amd64/arm64 的 sha256）
  - `vpn_server_hysteria_download_base_url`: `apernet/hysteria` → `HyNetworks/hysteria`
  - `vpn_server_xray_version: "26.3.27"` + checksums（[release v26.3.27](https://github.com/XTLS/Xray-core/releases/tag/v26.3.27)）；执行时快速过两项目 changelog 确认无 config 格式 breaking（26.3.27 新增 Finalmask/XDNS/XICMP 均为可选特性）
- 新增 `tasks/firewall.yml`（并在 `tasks/main.yml` include，加 `firewall` tag）：检测 nft/iptables，放行 **UDP 20000-30000** 入站（幂等写法：`iptables -C ... || iptables -I ...`，nftables 用 `nft list ruleset` 判断），不动既有其它规则
- `verify.yml` 增强：部署后检查 `ss -ulnp` 端口池监听（listen 范围生效）

### 2. hysteria 服务端配置重写（`ansible/secrets.yaml` 的 `VPN_HYSTERIA_CONFIG_YAML`）

解密现有内容后，按此目标形态重写（保留 auth 密码等既有密钥，新增 obfs password 用强随机值）：

```yaml
listen: :443,20000-30000      # port hopping 池（hy2 原生多端口监听，无需 DNAT；格式按官方 Port Hopping 文档执行时校验）
obfs:
  type: salamander
  salamander:
    password: <新生成强随机>
masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/   # 探测防御（obfs 下意义减弱，无害保留）
    rewriteHost: true
ignoreClientBandwidth: true   # 拒绝客户端走私 Brutal 带宽，默认走 BBR，降低行为特征
# tls/cert 段沿用 bing.com 自签（Salamander 加密整个 ClientHello，SNI 不可见，证书仅作 QUIC TLS 层）
```

> 修改后 `sops` 重新加密，走既有 `community.sops.load_vars` 流程，无需改 playbook。

### 2.x 研究发现的其它 hy2 高级特性适用性（为什么没有全上）

| 特性 | 本部署可用性 | 理由 |
|---|---|---|
| Chrome QUIC 指纹对齐（Parrot，2.11+） | ✅ 随 2.13.0 升级自动生效 | hy2 服务端默认开启；但 mihomo 客户端用自家 quic-go 实现无 parrot 开关——**Salamander 开启后整个 QUIC 握手被加密，指纹不可见，此项自然失去意义**（两者是互斥路线） |
| Gecko 分片 | ⚠️ 暂不采用 | 野心打在 GFW「不跨报文重组」软肋，但生态支持在 sing-box 侧，**mihomo 是否支持 gecko 未知**（obfs 必须两端一致）；且 Salamander 已把整个 ClientHello 加密，gecko 针对『无 obfs 路线被解密读 SNI』的场景，攻击面已被 Salamander 覆盖。若日后 mihomo 支持 gecko 且封锁升级，再切换 |
| ECH（2.10+） | ❌ 不适用 | ECH 用于『真 HTTPS 域名 + 公开 ECHConfig』部署把 SNI 加密；与自签 bing.com + skip-cert-verify 的现有体系不兼容，且 Salamander 开启后 SNI 本就不可见（互斥） |
| Mimic（eBPF UDP→TCP 包头伪装，2.12+） | ❌ 不适用 | ① 需要**两端**都跑 hack3ric/mimic 的 eBPF 程序（Linux + root），客户端是 mihomo（ImmortalWrt 容器/macOS），栈不支持；② 官方文档明确**与 port hopping 互斥**——二选一，已选拍 port hopping；③ 行为级 DPI 下未验证 |
| TCP Brutal v2（TCP 侧恒速+丢包补偿） | ⏸ 本次不启用，见附录 A | 作用于 Xray TCP 备线而非 hy2；两个坑：家宽客户端动态 IP 与 brutalctl 规则锚定冲突、社区实测 brutal 行为特征显眼易触发封锁（只是备线不值得冒验） |

> 结论：phy2 UDP 侧的可用对抗手段（port hopping + obfs + 版本最新化）已全部纳入本计划；其余项或互斥或不兼容客户端栈，列入上表备查。

### 3. 客户端 mihomo 配置（`~/.nixfiles/secrets/.config/clash/config-whitelist.enc.yaml`）

所有 hysteria2 出站节点追加/对齐字段（mihomo v1.19.27 桌面 + 旁路由同源生效）：

```yaml
- name: "hy2-xxx"
  type: hysteria2
  server: <同现有>
  ports: 20000-30000      # port hopping（替换原 port 字段）
  hop-interval: 30
  password: <同现有>
  obfs: salamander
  obfs-password: <与服务端一致>
  skip-cert-verify: true  # 同现有
```

### 4. 生效路径

- **VPS 侧（3 台）**：worktree 内改完后 `ansible-playbook edge/vpn.yml`（会 restart hysteria/xray，每台断连几秒~1 分钟）
- **桌面 mihomo**：sops 配置更新后走既有 home-manager `programs.sops.decryptFiles` 流程 + pm2 restart clash-meta（无需改 nix 代码）
- **旁路由容器（用户拍板：SSH 直改，不重建镜像）**：`ssh root@192.168.31.2` 直接修改 `/etc/nikki/profiles/config.yaml`（hy2 节点加 ports/hop-interval/obfs 字段）→ 重启 nikki（`/etc/init.d/nikki restart`）。配套纪律：`.nixfiles` 里的 enc 源文件仍同步更新（本计划已含），避免日后偶发重建镜像时旧配置回归 |

### 5. Xray 备线强化（回应：v26.3.27 新特性能否开启）

> 前提：Xray 配置在 `VPN_XRAY_CONFIG_JSON`（sops 密文），现状入站形态待执行时解密确认。以下为分层结论。

**第一层：本轮必做（与 binary 升级同步）**
- 确保主入站为 **VLESS + REALITY + Vision flow（xtls-rprx-vision）** —— 研究结论中存活纪录最好的 TCP 备线组合（REALITY 盗真站握手免证书 + Vision 防 TLS-in-TLS 检测）；若现有配置已是 REALITY，核对 Vision flow 是否启用，未用则补上
- REALITY 目标站（dest）检查：仅用 443 端口 + 借大站（官方警告：非 443 / 借小站极易连坐封 IP）

**第二层：本轮可选推荐（追加备线多样性）**
- 新增一个 **VLESS + XHTTP 入站**（xray v24.11+ 新传输，HTTP 语义可过 CDN）：域名复用 `*.soraliu.dev`（已有 Cloudflare DNS + caddy 基础设施），Cloudflare CDN 中转 → IP 层被拉黑时的兑底路线
- mihomo v1.19.27 已支持 VLESS + XHTTP 出站（执行时验证版本_clause）

**第三层：本轮不做（备查理由）**

| 特性 | 不启用的理由 |
|---|---|
| Finalmask（fragment/noise/Sudoku 流量塑形） | 参数需针对实际封锁形态调优，盲目开无收益；作为封锁升级后的「调优弹药库」备查 |
| XDNS（DNS 隧道） / XICMP（ICMP 隧道） | 保底通道需 xray 专用客户端运行（mihomo 不支持），主路由栈用不上；适用「TCP+UDP 双黑」极端期，届届时再起 |
| Xray 内置 Hysteria2 入站 + force-brutal | 与本次原生 hy2 2.13.0 部署完全冗余；适用无独立 hy 服务的场景 |
| XHTTP/3 + udpHop | UDP 路线（被 QoS 时同死），与备线「TCP 低调存活」定位矛盾 |

### 6. 不做的事（明确 out of scope）

- Nix 系 vpn-server/vpn-relayer profile 不升级（nixpkgs unstable 已 2.12.3，2.13 差异小）
- mihomo/nikki 内核不升级（功能已齐）
- Xray 配置（VPN_XRAY_CONFIG_JSON）内容不改，仅升 binary

## Files to modify

| 文件 | 改动 |
|---|---|
| `personal-k3s-ops/ansible/roles/vpn_server/defaults/main.yml` | hysteria 2.13.0 / xray 26.3.27 版本 + checksum + URL 改名 |
| `personal-k3s-ops/ansible/roles/vpn_server/tasks/firewall.yml` |（新增）UDP 20000-30000 放行 |
| `personal-k3s-ops/ansible/roles/vpn_server/tasks/main.yml` | include firewall.yml |
| `personal-k3s-ops/ansible/roles/vpn_server/tasks/verify.yml` | 端口池监听检查 |
| `personal-k3s-ops/ansible/secrets.yaml` | `VPN_HYSTERIA_CONFIG_YAML` 重写（sops） |
| `~/.nixfiles/secrets/.config/clash/config-whitelist.enc.yaml` | hy2 节点 ports/hop-interval/obfs 字段（sops） |
| `personal-k3s-ops/ansible/secrets.yaml` 的 `VPN_XRAY_CONFIG_JSON` | 第一层：核对/补 Vision flow + 443/dest 合规；第二层（若做）：追加 VLESS+XHTTP 入站（sops） |

## Steps

- [x] 1. `personal-k3s-ops`：fetch origin 后开 worktree 分支（`feat/hysteria-2.13-hardening`）
- [x] 2. 获取 hysteria app/v2.13.0 与 Xray v26.3.27 的 release checksums → 更新 `defaults/main.yml`（版本/URL/checksum + xray）
- [x] 3. 新增 `firewall.yml` task + `main.yml` 接线 + `verify.yml` 增强
- [x] 4. `sops -d ansible/secrets.yaml` 查看现有 hysteria config（daemon 侧现状确认）→ 按目标形态重写 → `sops` 重新加密提交；同时解密 `VPN_XRAY_CONFIG_JSON` 确认 Xray 入站形态 → 按第 5 节第一层核对/补齐（Vision flow + 443/dest），若选第二层则追加 VLESS+XHTTP 入站 → 重新加密
- [x] 5. `~/.nixfiles`：开 worktree 分支 → sops 编辑 `config-whitelist.enc.yaml` 的 hy2 节点 → 重新加密
- [x] 6. Ansible dry-run（`--check`）过 4 台后正式部署（先 primary 确认再推其余，含 vpn_premium，视当时手感）
- [x] 7. 桌面端激活新 mihomo 配置（pm2 restart）
- [x] 8. 旁路由：`ssh root@192.168.31.2` 直改 `/etc/nikki/profiles/config.yaml`（同 enc 内容）+ `/etc/init.d/nikki restart`
- [x] 9. 全链验证（见下）
- [ ] 10. 两仓库分别提 PR（squash 合并原则）；本 plan 文件 mv 进 `.nixfiles` worktree 随 PR 提交，主工作区不残留

## Verification

1. 服务端：`hysteria version` = 2.13.0；`ss -ulnp` 显示 20000-30000 监听；`systemctl status hysteria xray`；`xray version` = 26.3.27
2. 防火墙：控制机 `nc -u <vps> 25xxx` 探活 或 hysteria 客户端实测连接
3. 客户端：mihomo 面板/日志无 outbound 报错；经旁路由 `curl ipinfo.io` 出口正确；速度测试（openspeedtest / speed.cloudflare.com）对比升级前
4. 观察期：24–48h 内家宽/移动双网络下 QoS 断流频率对比（用户体感为准）
5. 回滚预案：任一 VPS 异常 → git revert 对应 PR + 重跑 playbook 回到 2.7.1 旧配置；客户端去掉 obfs/ports 字段即恢复旧行为

## Risks

- Salamander 服务端/客户端密码不一致 → 全部连不上（验证步骤 3 兜底，回滚预案覆盖）
- listen 端口范围写法与 2.13 实际语法出入 → 部署时 hysteria 启动失败即暴露（verify 步骤 1）
- VPS 提供商存在未知云防火墙 → 端口池不通，表现为连接超时（届时控制台排查，决策点已确认主要走系统防火墙）

## 附录 A: TCP Brutal v2 —— 可用性结论与启用手册（本次不启用）

### 结论：技术上可用，但本环境不建议现在启用

1. **作用对象错位**：它加速的是 **TCP 链路**（Xray REALITY/XHTTP 备线），与 hysteria2 无关；本次 hy2 主链路不受影响。
2. **家宽动态 IP 冲突**：`brutalctl add <客户端IP>/32 <rate>` 规则锚定客户端 IP，而家宽 PPPoE 重拨/运营商重分配会导致规则静默失效；改为大网段 CIDR 规则会连带影响同 VPS 上 caddy（headscale/alist）的正常访问者。
3. **行为风险**：社区实测 brutal 固定速率发送特征显眼、更容易触发 ISP 封锁（hysteria#1267 + RPRX 陈述）；备线的定位是低调存活，不适合挂显眼特征。

### 启用条件（何时回头看）

- Xray REALITY 备线实测速度明显受限（如 <10Mbps）且丢包型劣化归因明确（iperf3 测丢包率）

### 启用方法（届时执行）

```bash
# VPS 为 Linux ≥5.10；装 DKMS 内核模块
# https://github.com/HyNetworks/tcp-brutal （v2）
brutalctl add <客户端公网IP>/32 200   # 单位 Mbps，设为实测线路的 ~90%
# 家宽 IP 漂移处理：cron 脚本对比 wtmp/最新连接 IP，变化时重建规则
# 验证：cat /proc/net/tcp_brutal/rules；客户端 iperf3 -R 观察恒速效果
```

### 与 Xray 备线的组合现状

- 本计划已把 xray 升到 26.3.27 stable；若日后 XHTTP/REALITY 连接提速需求明确 → 服务端装 tcp-brutal + 规则化（上表手册），客户端零改动（v2 无需应用配合）。
