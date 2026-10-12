# 内网 Jumbo MTU 与旁路由 VPN 传输效率研究报告

> 研究执行：2026-10-12（研究合成 v1）／同日更新 v2（并入 GATE-1 实验 E1 结果）｜ SDD workspace：`.superpowers/sdd/jumbo-mtu-research/`（六份详细报告 = 五份研究 + E1 实验报告，含 review 记录，git-ignored）
> 证据链约定：本报告所有数字/结论均溯源到六份 task 报告（标注如「Task 1 §1」「E1 §2」），task 报告引用 `docs/network/data/` 原始数据文件（75 个）。本文不引入报告之外的新事实；所有【推断】标签沿用原报告证据分级。

## TL;DR 结论矩阵

| 方向 | 可行性 | 预期收益 | 一句话依据 |
|---|---|---|---|
| **内网 9000（全域）** | ❌ **不成立** | Apple 端点无法参与，仅剩 NAS↔PVE 子路径的理论可能 | Mac en11 = X520/82599，macOS 驱动 `AppleEthernetIXGBE` MTU 上限 **2034**（实测，Task 1 §1）；同款卡的 M4（.4）推断同样封顶（Task 3 R4）；9000 全档在本栈不成立（Task 3 总体预判） |
| **内网 2034 档**（Mac↔NAS / Mac↔M4） | ❌ **不可行——哑交换机 1518B 边界实锤（E1 实验）** | 当前为负（超限帧静默丢弃）；**换支持 ≥9018B 帧的交换机即可解锁**（端点 Mac 2034+/NAS `maxmtu 16334` 就绪，M4 推断同 2034、PVE 待探）——解锁后量化预期见 §5.1，A/B 待换机后定标 | E1：2034 帧 UDP 洪泛 37,375 包 **0 到达**（阳性对照 1400B 53,664 包精确入栈，方法自证）+ 边界悬崖 **1472B payload（1518B 帧，802.3 标准帧）PASS / 1473B（1519B）FAIL**——哑交换机零 jumbo 能力，唯一决定性短板（E1 §2） |
| **VPN（hy2 over QUIC）** | ✅ **零风险但零吞吐收益**——不为 VPN 做任何 MTU 变更（2034 档对跨网 TCP 大包的影响见 §4.3/§9 A3 G2；E1 已证公网方向 DF 大包不出网卡即被本机 PMTU cache 拦截，见 §7.2） | 隧道吞吐 ≈0、隧道协议腿 CPU ≈0；唯一理论收益是 LAN 第一腿 MSS 1460→1994 带来的容器 CPU **−2~5%（相对，可信度低）** | QUIC 单包硬上限 1452B 与 underlay MTU 完全解耦（三份 quic-go 源码 + 运行版复验，Task 4 R1/R2；实测 1000 包 0 个 >1452，Task 5 §1.3）；公网 path-MTU 1480 硬边界（Task 2 A6） |
| **低风险优化项**（不动 MTU） | ✅ 立即可做 | 修复既有缺陷 + 核对性能前提 | QUIC buffer 核对（容器 netns）、桌面 mihomo pm2 常驻状态核对、fw4 `mtu_fix` nft 规则未生效修复（Task 2 A4 / Task 4 R7 / Task 5 §1.5） |

**置信度披露**：2034 档判定的丢帧归因存在残余不确定性——E1 无 root 设计无法完全排除「Mac X520 驱动 RX 硬件长度上限跟随 en11 MTU=1500 静默截断且不计计数器」的替代解释，归因置信度标注「**高但非绝对**」；一次性甄别法已入库 GATE-2 议题（换机前以 Mac 2034 + NAS `InJumboPackets` 复测，见 §7.1/§8）。

**核心判断**：9000 全档维持不成立；2034 档已被 E1 实测否决——瓶颈不在端点而在哑交换机 1518B 硬阈值；VPN 链路与 MTU 无关（实证链），相关动作只剩低成本修复项（GATE-1 已纳入 Task 6a）。下一决策点是 **GATE-2**：换机评估（型号确认 / 丢弃位甄别 / 采购阈值）+ A2 补做授权（§8）。

---

## 1. 背景与研究方法

### 1.1 研究动机与边界

内网当前全链 MTU 1500。研究问题：启用 jumbo（原目标 9000）能否提升两条链路的效率——(a) 内网大流量（Mac↔NAS、开发机间）；(b) 旁路由 VPN（ImmortalWrt/mihomo → hysteria2 QUIC → 4×VPS）。全程只读授权（SSH NAS/VPS 只读、sops 白名单字段），任何 MTU 变更属独立 gate：GATE-1（本报告研究结果呈现）→ GATE-2（落地方案 approve）→ 低峰窗口执行（plan Context/Global Constraints）。

环境澄清（避免误判，Task 1 §2/§3）：Mac 的 utun7 = Nebula overlay（mtu 1300，承载 k8s API），不承载 `192.168.31.0/24` 业务流量；系统代理此刻 disabled、桌面 mihomo 未运行（pm2 空表）——对 MTU 研究无干扰，但影响 H4 前置（§9）。

### 1.2 物理拓扑（plan 原图 + 实测标注）

```mermaid
flowchart LR
    subgraph LAN["192.168.31.0/24（现全链 MTU 1500）"]
        R["主路由 .1 小米万兆（SKU RC01 推定❓见 §8）<br/>固件无 LAN MTU 项✗ / LAN 桥不在 Mac↔NAS 路径（GATE-1 确认）"]
        SW["哑交换机（型号未知）<br/>E1 实测：1518B 硬阈值✗（2034/9000 均不透传）"]
        MAC["Mac .120 en11<br/>X520/82599 SFP+ DAC 10G<br/>macOS 驱动上限 2034【实测】"]
        M4["M4 .4（mDNS 确证）<br/>同款 X520 10G<br/>推断同封顶 2034【推断】"]
        PVE["PVE（.103/.104 ARP 见 PVE VM MAC）<br/>宿主机/网卡/上联未确认❓"]
        NAS["NAS .3 DXP4800 Plus<br/>AQC113 10G（atlantic）maxmtu 16334【实测】"]
        WRT["ImmortalWrt .2（docker macvlan on eth0）<br/>mihomo v1.19.32 tproxy :7892【实测】"]
        IOT["Wi-Fi/IoT（802.11 MSDU 2304 天花板）<br/>永久 jumbo 豁免段"]
    end
    VPS["4×VPS hy2 2.13.0<br/>QUIC 恒 ≤1452B【源码+实测】"]
    MAC --> SW
    PVE --> SW
    SW --> R
    MAC -->|default gw| WRT
    WRT -.->|macvlan on eth0| NAS
    NAS -->|同台（GATE-1 用户确认，主路由不在路径）| SW
    R --- IOT
    WRT -->|公网 path-MTU 1480【实测】，PPPoE 型（推断）| VPS
```

关键拓扑语义（Task 1 §2）：

- Mac 的默认网关是旁路由 `.2`，但内网 /24 目标（.1/.3/.4）均为 **host route 直连**（L2，不经 .2 转发）——Mac↔NAS 大文件与 Mac→公网 VPN 是两条完全不同的路径，MTU 影响链分别评估。
- **Mac↔NAS 的物理 L2 路径已由用户在 GATE-1 人工确认**：NAS 10G 口与 Mac **同接哑交换机**，主路由 LAN 桥不在 Mac↔NAS 路径（修正 plan 原图“NAS 直连主路由”的假设）——原疑似的「主路由 br-lan（默认 1500、固件无设置项）封顶」判据就此移除，L2 判据收敛为哑交换机单项，且已被 E1 实测否决（§7）；哑交换机上联主路由（SW→R）仅承载跨子网/WAN 流量。
- 旁路由容器是 NAS eth0 上的 macvlan（`.2`），宿主 shim 接口 `macvlan-shim`（`.250`）解决宿主↔容器互通。

### 1.3 研究方法：SDD 5 任务 + review 循环

数据先行原则：4 个数据/调研任务全部只读完成、经 per-task review 修正后，第 5 个任务综合设计基准测试矩阵并执行只读基线；GATE-1 批准后追加 E1 实验段（A1 透传判定）。任务分工与 review 闭环情况（ledger 详见 §11.3）：

| # | 任务 | 产出 | review 闭环 |
|---|---|---|---|
| 1 | `mtu-lan`：内网物理拓扑与 MTU 能力矩阵（Mac 本机视角） | 13 数据文件 + report | 1 轮 APPROVED（5 minor deferred） |
| 2 | `mtu-vpn`：旁路由容器与 VPN 数据面收集（NAS/容器/VPS/仓库视角） | 13 数据文件 + report | 1 轮 APPROVED（4 minor deferred） |
| 3 | `mtu-jumbo`：jumbo 技术可行性文献研究（引用级证据） | report（无数据文件） | 1 轮 fix（2 个 I 级 finding）→ APPROVED |
| 4 | `mtu-quic`：hy2/QUIC/mihomo MTU 行为源码研究 | report（无数据文件） | 1 轮 fix（2 个 I 级 finding）→ APPROVED |
| 5 | `mtu-bench`：基准测试矩阵设计 + 只读基线执行 | 30 数据文件 + report | 2 轮 fix → APPROVED（11 findings 全闭环） |
| 5-E1 | `mtu-exp1`（GATE-1 批准后）：LAN 透传判定（A1）+ PMTUD 探测（A3）；A2 中断跳过、E2 取消 | 19 数据文件 + exp report | A1/A3 闭环；变更纪律台账与中断事件见 §7.4 |

关键 review 修正（已在各 task 报告内体现，本文沿用不回退）：① retransmits 前向=N/A / 反向真值 64/257；② CPU 主口径钉 iperf3 内建 `cpu_utilization_percent`；③ Task 3/4 收益量化重标定为两档制（2034 现实档 / 9000 供他机参考档）；④ M4 同封顶 2034 保持【推断】标签不升格为实证（Task 3 fix round 1 / Task 4 fix round 1）。

### 1.4 数据文件索引（75 个，`docs/network/data/`）

| 组 | 文件（组内列举） | 数量 | 支撑章节 |
|---|---|---|---|
| task-1 本机探测 | ifconfig-a / system-profiler-ethernet / networksetup / utun-owner / scutil-proxy / pm2-list / arp / oui / mdns / router-probe / pathmtu / traceroute / netstat | 13 | §2（设备能力与拓扑）、§3 |
| task-2 容器与 VPN 数据面 | nas-network / nas-nic / docker-network / container-net / uci / mssclamp / tproxy-mode / mihomo-config / desktop-config / vps-all / vps-primary / vps-pathmtu / pathmtu | 13 | §4（VPN 数据面）、§10 |
| task-5 LAN 基线 | lan-single-r1..5 / lan-4p-r1..5 / lan-rev-r1,2 / lan-30s / lan-summary / mac-netstat-en11 / mac-cpu-30s / nas-lan-snapshots | 17 | §3 |
| task-5 VPN 基线 | vpn-curl / vpn-summary / nas-vpn-snapshots / mac-netstat-en11-vpn | 4 | §4 |
| task-5 QUIC/GSO | quic-baseline.pcap / quic-download.pcap / quic-pktlen-hist / gso-burst-evidence / gso-check / gso-vps | 6 | §4 |
| task-5 环境与发现 | mac-env / nas-env / ugos-and-nic-stats | 3 | §3、§9 |
| task-5-exp（E1 实验） | 00-snapshot / a1-2034 / a1-rollback / a1-passthru-2006 / a1-calib / a1-stats×2 / a1-udpflood×2 / a1-bisect×2 / a1-verdict×2（v1 无效轮存档）/ a1-edge-a3 / a3-pmtud-public×2 / a2-prep×2 / a2-container | 19 | §7（E1）、§9（实验状态） |

task-3/4 为纯文献/源码研究（引用内嵌于报告正文），无数据文件。

---

## 2. 内网设备能力矩阵与物理拓扑（Task 1 + Task 3）

### 2.1 设备 × 档位能力矩阵

| 设备/组件 | 网卡·链路 | 9000 | 2034 | 证据等级 | 关键备注 |
|---|---|---|---|---|---|
| **Mac .120（en11）** | Intel X520/82599 SFP+ DAC（TB PCIe 转接），协商 10Gbase-Twinax | ✗ 驱动不可 | ✓（即上限） | 【实测】 | `networksetup -listvalidMTURange en11` = **1280–2034**（`docs/network/data/task-1-networksetup.txt`）；驱动级 `max-mtu`，GUI/ifconfig 均无法绕过（Task 3 R4）；DF payload 现实上限 2006 |
| **M4 .4** | 同款 X520（同 OUI `90:e3:ba`，仅一号之差；设备 ID 确证 82599） | ✗（推断） | ✓（推断） | 【推断】 | 无 SSH 授权；若同为 macOS + IXGBE 驱动则同封顶 ~2034（Task 3 R4，Task 1 §6 同判）；待用户侧验证（§8 #3） |
| **NAS .3** | AQC113 10G（atlantic，fw 1.3.31，已协商 10000Mb/s） | ✓ 硬件 | ✓ | 【实测+文档】 | `maxmtu 16334`（`docs/network/data/task-5-gso-check.txt`）；AQC 系 datasheet 16KB jumbo；UGOS Pro ≥1.0.0.0888 起 GUI 可设 9000（版本待核，§8 #4）；注意个别版本"设后回落 1500"持久化 bug（Task 3 R3） |
| **主路由 .1** | 小米万兆（身份实测为小米；RC01 推定待证） | 固件✗ / 硬件可能 | 不在路径（GATE-1 确认） | 【社区共识+推断】 | 官方固件无 LAN MTU/jumbo 设置项（WAN 侧 PPPoE 微调除外）；IPQ9570 平台硬件大概率支持大帧；可控路径=刷 QWRT（不建议为此刷机）（Task 3 R1）；**LAN 桥不参与 Mac↔NAS L2 转发**（§1.2）——其 jumbo 相关性收敛为零，仅余跨界（WAN/Wi-Fi）规格核对价值（GATE-1 #2） |
| **哑交换机** | 型号未知（无管理面板） | **✗（E1 实测）** | **✗（E1 实测）** | 【实测】 | **最大转发帧 = 1518B（含 FCS，802.3 标准帧），零 jumbo / baby giant 能力**：1472B payload PASS / 1473B（1519B）起丢弃，硬悬崖非渐变（E1 §2.4，§7.1）；文献预期（同类产品 9–16K 普及，Task 3 R2）被实测推翻；换 ≥9018B 设备即解锁 |
| **macvlan `macnet` ± shim** | NAS eth0 上的 macvlan（.2 / .250） | 跟随 parent | 同 | 【源码+待实测】 | docker 不支持给 macvlan 显式设 MTU（moby issue/源码）；内核强制 macvlan ≤ parent；parent 抬升后实际值必须重核（当前 1500 环境无法区分继承源）（Task 3 macvlan 节） |
| **ImmortalWrt 容器网络栈** | br-lan + fw4 | 可配 | 可配 | 【文档】 | 正确改法是 `config device` section；br-lan 改 MTU 有锁死管理面先例（GL.iNet 案例），改前必须留 1500 备用通道（Task 3 R5） |
| **Wi-Fi/IoT 设备** | 802.11（含小米 IoT、家电、手机、回音壁） | ✗ | ✗ | 【文档证实】 | 802.11 MSDU 2304 硬限制（mac80211 kernel limitation），永久豁免段；风险在有线→无线跨界（Task 3 R6） |
| Mac en7（USB RTL8153，inactive） | — | ✗（上限 1500） | ✗ | 【实测】 | 当前无链路（Task 1 §1） |

### 2.2 内网设备清单（Task 1 §4，ARP 22 条 + OUI + mDNS）

| IP | OUI/厂商 | 推测类型 | 证据 |
|---|---|---|---|
| .1 | Xiaomi | 主路由（万兆 SKU 待补，GATE-1 #2） | HTTP title；traceroute 第 2 跳 |
| .2 | 本地管理 MAC（`02:42`） | 旁路由容器 ImmortalWrt（macvlan） | Docker 生成惯例；默认网关（实测） |
| .3 | Ugreen | NAS DXP4800 Plus | mDNS `_smb._tcp` 实例 "DXP" |
| **.4** | `90:e3:ba`（与本机 en11 同批 X520） | **M4 主机（Apple 桌面机）** | mDNS `M4.local` → .4 + .32 双地址（Task 1 修正：非 PVE builder） |
| .32 | Apple | M4 的板载网络接口 | M4.local 第二地址 |
| .103 / .104 | Proxmox | PVE 上的 VM（宿主机不明，GATE-1 关联盲区） | PVE 默认 VM MAC 段 |
| .250 | 本地管理 MAC | macvlan-shim（宿主↔容器互通；Task 1 早期猜测已被 Task 2 推翻修正） | `ip -4 addr`（Task 2 A1） |
| .144/.150/.170/.196/.229/.232 等 | Xiaomi / Midea | 小米 IoT 与美的家电（约 8 台） | OUI |
| .225 等无线终端 | Xiaomi / Apple | 手机/笔记本（Wi-Fi，永久 1500 段） | OUI / mDNS |
| .224 / .228 | 随机化 MAC | 疑手机（Wi-Fi random MAC） | locally administered 位 |

另见（未入 ARP 固定地址）：Samsung 回音壁、iPhone（mDNS）——均 Wi-Fi 段，不参与 jumbo 域。utun7 = Nebula overlay（mtu 1300，承载 k8s API，Task 1 §3）不承载内网业务。注：Task 1 早期对 `.250` 的“疑手机”猜测已被 Task 2 的 macvlan-shim 事实推翻修正（ledger deferred F003），本表按最终结论收录。

### 2.3 两项 L2 生死判据的最终裁定（GATE-1 + E1）

内网 2034 档能否成立，最终取决于**两个实测点**（Task 3 移交清单 + Task 5 A1），两项现均已闭环：

1. **哑交换机 2034 帧透传能力——已实测：FAIL。** UDP 洪泛置底判定 + 边界二分：最大转发帧 1518B（含 FCS），2034 帧 0 到达（E1 §2，详见本报告 §7.1）。
2. **Mac↔NAS 是否穿主路由 LAN 桥——已确认：不在路径。** GATE-1 用户人工核对（traceroute/ARP 无法分辨的项）：NAS 10G 口与 Mac 同接哑交换机，主路由 br-lan（默认 1500、固件无设置项）不参与该 L2 转发。

**裁定：内网 2034 档当前不可行——短板收敛为哑交换机单项（端点就绪或推断就绪），修复路径 = 更换支持 ≥9018B 帧的交换机**（E1 §2.6）。残余不确定性（丢弃位归因的替代解释）与一次性甄别法见 §7.1。

不确定性边界的演化存档（诚实标注）：研究期的 ARP/mDNS/traceroute 全部探测均为逻辑拓扑证据——该盲区已由 GATE-1 人工核对消除；当前唯一开放的物理层不确定性是 E1 丢帧归因（哑交换机 vs Mac X520 RX 硬件阈值，置信度「高但非绝对」，§7.1）。

---

## 3. 内网链路基线（Task 5 §1.1，全链 1500，只读）

### 3.1 LAN 吞吐与包速率（Mac .120 → NAS .3，host route 直连）

| 指标 | 单流 ×5 轮 | 4 流 ×5 轮 | 30s 满载窗 |
|---|---|---|---|
| 各轮吞吐 (Gbps) | 6.96 / 6.94 / 7.18 / 6.75 / 6.68 | 6.47 / 5.68 / 5.10 / 5.19 / 6.42 | 5.78 |
| **中位 (Gbps)** | **6.94** | **5.68** | — |
| retransmits | **N/A**（macOS sender 侧 JSON 无此字段，不读不存在字段） | N/A | N/A |
| NAS 整机 busy（/proc 差分参考口径） | 17.4–23.0% | 28.8–34.1% | — |
| NAS busy（iperf 内建 `remote_total` 主口径） | 单流 r1 ≈ 44.6% | ≈ 61.8%（5 轮中位，56.3–68.0） | — |
| Mac en11 出向 pps（收紧配对复算） | 0.53–0.58 Mpps | 0.43–0.52 Mpps | **0.490 Mpps**（in ACK 17.4k） |

反向（NAS 发送，sender=NAS）：**8.13 / 7.96 Gbps**，`sum_sent.retransmits` 真值 **64 / 257**——这是全组唯一的 retransmits 实测口径（Task 5 §1.1 修正后主表）。冒烟 RTT 0.412ms 证直连。NAS 空闲本底 busy 10.1%（141 天 uptime 的常驻负载）。数据：`docs/network/data/task-5-lan-summary.txt` 及 17 个 lan-* 文件。

**基线形态解读**（Task 5 §1.1 发现）：a) **4 流反而低于单流**且 NAS busy 更高——NAS 接收路径（软中断/驱动）是 1500 档的多流瓶颈候选，恰是 jumbo 要解决的形态（H3 判读素材）；b) Mac 发送 6.9G vs NAS 发送 8.0G，不对称 ~15%；c) 490k pps @ 5.78Gbps ≈ 1477B/帧，与 MTU 1500 自洽——**2034 档同吞吐预期锚点 ÷1.37 ≈ 358k pps**（未来 on/off 对照的硬判据）。

### 3.2 包计数本底（B6，供未来 on/off 对比，`docs/network/data/task-5-vpn-summary.txt`）

| 场景 | 窗口 | Mac en11 | 说明 |
|---|---|---|---|
| LAN 满载（Mac→NAS 5.78Gbps，MTU 1500） | 30s | **out 490,238 pps / in(ACK) 17,372 pps** | ≈1477B/帧；2034 档预期同吞吐 ÷1.37 ≈ 358k pps |
| VPN 满载（下载 ~130Mbps，4 个有效 30s 中窗） | 4×30s | **in 11.7–12.8k pps / out(ACK) 0.97–1.3k pps** | 第一腿 MSS 1460；即 H3 的 pps 判据基线（2034 档预期 in ≈ 9.0k pps @ 同吞吐） |
| NAS eth0（PROMISC，计数含非 NAS MAC 的环境帧） | 各轮 | 满载 13.6–15.5kpps | 口径注意：Mac↔.2 流量亦被计入 |

### 3.3 CPU 采样口径规范（GATE 后所有实验的主尺，Task 5 §1.1.1）

实测发现两套口径在同窗内方向相反、幅度均近 **2×**（Mac：top 32.6% vs 内建 16.5%；NAS 单流：/proc 差分 23.0% vs 内建 remote 44.6%）——系统计目标与采样窗的语义差异，**各自内部自洽、互相不可换算、禁止混排**。钉死规范：

1. **LAN iperf3 轮：`cpu_utilization_percent`（host=Mac、remote=NAS）为唯一主口径**（与吞吐同窗同 JSON 自动产出）。
2. 参考口径（仅异常时同窗复核，不参与判读）：Mac `top -l 2 -s 8` 第二样本；NAS `/proc/stat` 首行差分。
3. **VPN/mihomo 腿：`/proc/<pid>/stat` utime+stime 差分为唯一主口径**，pid 须窗口内 `pgrep -fx` 动态解析（nikki 会重载），**每实验窗配同长 idle 参照窗扣背景**。
4. on/off 只做同口径相对比较；出现 ~2× 矛盾先用参考口径回核同窗。

---

## 4. VPN 数据面与 QUIC 行为（Task 2 + Task 4）

### 4.1 数据面事实（Task 2）

- **公网 path-MTU = 1480**（PPPoE 型）：NAS → 两台 VPS 均 1452 payload ✅ / 1453 ❌（内核回 `local error: message too long, mtu=1480`）；Mac 侧公网对照同值且表现为 DF 黑洞（1453+ 无 ICMP 回应，多次复测稳定）。8972 档失败——**内网 jumbo 无法穿透 PPPoE 出网，硬边界**（Task 2 A6）。
- NAS 与容器全接口 1500（macnet 无显式 MTU 配置，继承默认）；mihomo **tproxy :7892**（TCP+UDP，nft 链活跃，计数 232 万包），**容器内无 tun 接口**，config 中 `tun.enable: true` 被 nikki 运行时覆盖未生效——无 tun 封装开销变量。运行二进制 **mihomo v1.19.32**（with_gvisor）。
- hy2 服务端 ×4 一致：v2.13.0、listening `:20000-30000` port hopping、`udpIdleTimeout: 90s`、`ignoreClientBandwidth: true`、**QUIC 高级参数全部默认**（Stream/Conn 窗口 8/20MB、maxIdleTimeout 30s、DPLPMTUD 开启）；VPS 出口接口 1500；sysctl rmem/wmem 64MB（`docs/network/data/task-2-vps-all.txt`）。

**出网 path-MTU 实测表**（NAS 本体，容器 BusyBox ping 无 `-M do` 的等效替代；`docs/network/data/task-2-pathmtu.txt`）：

| ICMP payload | 总 IP 包 | → vpn_primary (45.202.255.241) | → vpn_premium (103.112.1.197) |
|---|---|---|---|
| 1400 | 1428 | ✅ 100% | ✅ 100% |
| 1452 | 1480 | ✅ 100% | ✅ 100% |
| **1453** | **1481** | ❌ `local error: message too long, mtu=1480` | ❌ 同左 |
| 8972 | 9000 | ❌ | ❌ |

**hy2 服务端 QUIC 相关配置表**（4 台一致；默认值源码/官方文档，task-2 C3）：

| 字段 | 显式配置 | 未显式时的官方默认 |
|---|---|---|
| listen | `:20000-30000`（port hopping 池） | — |
| udpIdleTimeout | 90s | 60s |
| ignoreClientBandwidth | true（服务端不采纳客户端带宽上报） | false |
| quic.initStreamReceiveWindow / maxStreamReceiveWindow | 未配置 | 8388608（8MB） |
| quic.initConnReceiveWindow / maxConnReceiveWindow | 未配置 | 20971520（20MB） |
| quic.maxIdleTimeout | 未配置 | 30s |
| quic.disablePathMTUDiscovery | 未配置 | false（DPLPMTUD 开启，自动在 1480 路径收敛） |

其余服务端事实：sysctl 64MB ≫ QUIC 默认窗口 8/20MB，**无缓冲区瓶颈**；4 台均无 UDP 443 监听（入口即 hopping 池，与 defaults 注释存在记录性偏差，不影响 MTU 结论）；VPS→家反方向 ICMP 全丢弃（入站全无响应，无法直接测反向 PMTU，Task 2 缺口 2）。

### 4.2 QUIC 行为（Task 4，源码实证 + Task 5 实测复核）

- **单包硬上限 1452B 与 underlay MTU 完全解耦**：quic-go `MaxPacketBufferSize = 1452` 写死（以太网预算），三个实际运行的实现（apernet fork、metacubex fork、upstream）逐行一致；运行版 v1.19.32 的依赖钉版（`2548683b76f4`）已独立复验不改。quic-go **不读网卡/路由 MTU**；GSO 分段尺寸 = 当前包大小（≤1452），不是接口 MTU。"9000 MTU 接口上会不会自动用大包"的答案是**否**。
- **DPLPMTUD（RFC 8899）**：二分搜索，起点 1250（Chrome parrot 指纹）/1280，每 5×RTT 一个 PING probe，探测上限 = min(对端 `max_udp_payload_size`, **1452**)，每生命周期 <10 个 probe；port hopping 走 `DisablePathManager` 不重置搜索。
- **实证**：满载窗 1000 包样本（VPS 侧 pcap ×2），隧道腿 UDP payload **众数 1443B、0 个 >1452**——与源码断言完全吻合（1452 上限 − quic-go 在 1480 path 的收敛）。baseline 窗 84.6% 为 1443B（`docs/network/data/task-5-quic-pktlen-hist.txt`）。
- **GSO/GRO 抵消因素**：发送侧 UDP GSO 默认开（一次 syscall ≤20KB 批 ≈ 14×1452B 包，Cloudflare 实测 syscall 904,539→18,824，≈48× 摊薄）；接收侧无 UDP GRO（recvmmsg 8/批）。三处 ethtool `tx-checksumming on`（NAS eth0 / 容器 macvlan / VPS ens3）实测满足 GSO 前提；满载 pcap 下行 gap 双模（<50µs 簇内 + 1–5ms 簇间）与 GSO 形貌一致——**该形貌证据属 VPS 发送腿，mihomo 腿运行时确认待负对照**（Task 5 §1.4 腿归属判读）。
- **mihomo tproxy = 纯用户态 relay**（`net.TCPListener` + `IP_TRANSPARENT`，`LocalAddr()` 取原始目标，无任何 MSS setsockopt）：underlay MTU 实际影响的只有两处——(a) **Mac↔mihomo LAN TCP 第一腿的 MSS**（内核按路径 MTU 协商）；(b) 无。mihomo↔VPS 包大小被 QUIC 1452 锁死。hy2 UDP relay 载荷上限 1197（`udp-mtu` 默认）。

### 4.3 现状缺陷：tproxy MSS clamp 未生效 + 黑洞敞口

| 位置 | 事实 |
|---|---|
| fw4 UCI | 容器 wan zone `mtu_fix='1'` 已配置 ✔ |
| 实际规则 | nft ruleset 3994 行中 **mss/mtu 规则 0 条** ✘——旁路由拓扑中 wan zone 无绑定接口，fw4 不为空 zone 生成 TCPMSS clamp（`docs/network/data/task-2-mssclamp.txt`） |
| 含义 | **当前全网无任何 MSS clamp**；公网 1480 路径实测为 DF 黑洞（无 ICMP 回执）——内网抬 MTU 后，跨网 TCP 大包仅靠各端自身 PMTUD 兜底；quic-go/QUIC 侧有 DPLPMTUD 兜底不受影响 |
| 附注 | MSS clamp 本就只救 TCP；且 fw4 文档默认也仅对 wan zone 出向流量生效（Task 3 R5） |

此缺陷独立于本研究存在（现网 1500 下公网 1480 黑洞同样敞口），修复建议见 §10。

### 4.4 VPN 基线与瓶颈定位（Task 5 §1.2）

| 指标 | gw（tproxy 缺省路径） | proxy（显式 mixed :7890） |
|---|---|---|
| 稳态中位吞吐（55s × 1GB, OVH 源） | **130.8 Mbps** | **131.0 Mbps**（双路径等价，差 0.2% < 波动带 ±5–9%） |
| mihomo 进程 CPU（满载） | 单核 ≈ **21%**（21.2/19.1/20.4/22.5 ticks/s，NAS 6 核 → 整机 ~3.5%） | 同量级 |
| NAS 整机 busy（/proc 参考） | 8.4–11.9%，增量 ≤2%（噪声级，本底 10.1%） | 同 |

出口对照：两路径出口同为 `103.112.1.197 (colo=NRT)`——同一 mihomo 数据面、同一节点。**隧道瓶颈不在 NAS/mihomo CPU，应在公网路径**（与"隧道腿收益 ≈0"的机理预测互证）。背景噪声披露：mihomo 背景 ticks 7–37/s 与满载 21% 同量级——on/off 微差判读必须配 idle 参照窗（Task 5 §1.2，A4 规范据此）。

**VPN 零收益实证链**（多源互证）：① 源码——QUIC 不发 >1452 包、不读接口 MTU、GSO 段大小不变；② 实测——1000 包 0 个 >1452、众数 1443（= 1480 path 收敛值），`disablePathMTUDiscovery: false` 默认开即自动收敛；③ 路径——公网 1480 丟大包（1453+ 无 ICMP），9000 无法出网（Task 2 A6）；④ 基线——瓶颈在公网不在 CPU（§4.4）。结论：**任何内网 MTU 档位都无法提升 hy2 隧道吞吐，且因 QUIC 从不发 >1500 的 IP 包，也不产生新增黑洞风险**（Task 4 R3）。

---

## 5. 可行性结论（决策标准执行）

对照 plan「决策标准」逐条执行：

### 5.1 内网

- **9000 全域：不成立。** 判据链：Mac en11 驱动上限 2034（实测）＞ M4 .4 同款 X520 推断同封顶（Task 3 R4）→ Apple 端点无法参与任何 >2034 档位。9000 档仅"NAS ↔ PVE/未来 AQC 端点"子路径**可能**成立（NAS 硬件已证，PVE 网卡未知、无数据）——且同样被哑交换机拦路（E1 留档 8972 帧同路径 FAIL，`task-5-exp-a1-edge-a3.txt`）；小米路由器固件不提供 9000 入口（刷机不建议为此单独承担）。按决策标准：**存在硬件短板 → "当前不可行" + 替代方案评估**——替代档位即 2034（换机后）。
- **2034 档：当前不可行（E1 实测否决）。** 原三判据已收敛（§2.3）：拓扑确认主路由桥不在路径；哑交换机实测 1518B 硬阈值、2034 帧 0 到达——第三个实测点（macvlan 容器跟随值，bench 4）不再构成阻断（帧根本未达 NAS macvlan 段），但其验证仍是换机后解锁链的一环。**结论从 v1 的"可行但未证实"修正为：不可行——换 ≥9018B 交换机解锁**（E1 §2.6）；解锁后本节收益预期才可兑现、A/B 定标。
- **收益预期（两档量化，Task 4 R8 / Task 3 R7）**：
  - 现实档 2034：单帧负载 ÷1.37（包数 −26%），MSS 1460→1994；吞吐百分比级收益预期**低个位数**（现代 TSO/GRO/中断合并已摊薄每包成本）——但基线发现 4 流时 NAS 接收侧成瓶颈（busy↑ 吞吐↓，§3.1），该形态下包处理开销下降可能有超比例改善，**幅度必须由 GATE 后 A/B 实测定标**；pps 锚点 490k→~358k；mihomo 容器 CPU 预期 −2~5%（相对，可信度评估见 §5.2），NAS 接收路径幅度无先验、以 4 流瓶颈形态为主要观测意义。
  - 全幅档 9000（本机不可达，供未来换 AQC 系网卡/其它主机参考）：MSS 8960（÷6.1），容器 CPU 预期 −5~15%。
- Synology"jumbo 翻倍"案例源于弱 CPU NAS，对 8505/X520 组合**不具可迁移性**（Task 3 R7）。

**两档量化总表**（Task 4 R8/收益预判；jumbo off = 现状 1500；E1 后注：2034 档收益仅在哑交换机更换后可兑现，A/B 未执行）：

| 档位 | MSS | 包数 / syscall 变化 | 预期收益 | 适用对象 |
|---|---|---|---|---|
| 现状 1500 | 1460 | — | — | 全体（基线） |
| **2034 现实档**（ Mac en11 驱动上限） | 1994（÷1.37） | relay read/write 与 memcpy ÷1.37（↓~27%)；en11 中断 ÷~1.4 | 吞吐持平或低个位数（4 流形态待测）；mihomo 容器 CPU −2~5%（相对，§5.2 可信度评估） | Mac(≤2034)↔mihomo LAN TCP 第一腿、Mac↔NAS/M4 |
| 9000 全幅档（本机不可达） | 8960（÷6.1） | ÷6.1 | 容器 CPU −5~15%；包数 ÷6.2 | 其它支持 jumbo 的主机（PVE/AQC 系网卡） |

### 5.2 VPN

- **吞吐：实证零收益**（§4.4 实证链）——满足决策标准中"提升 <5% → 不值得"分支，**不进任何 MTU 变更**；
- **CPU：2034 档 mihomo 容器预期 −2~5%（相对量）的诚实可信度评估**：机理方向可靠（用户态 relay 的 read/write syscall ÷1.37，源码级事实），但**幅度是推断值未经定标**，且存在三重削弱因素——① 它是相对量：单核 21% 的 2–5% 相对 ≈ 0.4–1.05 个百分点单核，整机（6 核）<0.2pp，无运维可感知性；② 背景 ticks 7–37/s 与预期微差同量级（§4.4），不做同窗 idle 参照即被淹没；③ 该收益仅在 VPN 满载 + Mac↔mihomo TCP 腿全程 2034 时兑现（tproxy 拦截的是 LAN TCP 第一腿，若 Mac 只提 en11 而容器 macvlan 未跟随即吃不到）。**结论：方向可信、幅度不可信、价值不足——按决策标准"CPU 显著下降"分支未达标，不进 Task 6a 配置项**，仅保留 §10 低成本项。

---

## 6. 用户四大场景收益评估

### 6.1 Mac ↔ NAS 大文件（SMB/直连）

- **现状**：单流 6.94G / 反向 8.0G（§3.1），均已处较高水位；4 流 5.68G 且 NAS 接收 busy 偏高——**这是 jumbo 最对症的形态**。
- **2034 档解锁后（换机）**：吞吐低个位数提升（单流 6.94G / 反向 8.0G 已处较高水位，增量幅度待实验；4 流/接收受限场景可能更明显——基线瓶颈形态正是其观测窗口）；长时间大文件拷贝下双端包处理开销有小幅下降。
- **前提（已裁定）**：两项 L2 判据已判（§2.3）——哑交换机 1518B 阈值 FAIL → **换机前本场景零收益**；换机后 UGOS 版本核对（§8 #4）仍需（GUI 落地路径，实验用 CLI 不受阻）。谁受益：受益者是 NAS 接收路径软中断负载与时延抖动，人感知有限。

### 6.2 VPN 出口流量（Mac → 公网下载/上传）

- **隧道腿零收益**（实证链，§4.4）：吞吐维持 ~131Mbps（瓶颈公网），QUIC 包恒 ≤1452。
- 唯一变化：LAN 第一腿 MSS 1460→1994 → mihomo CPU −2~5%（相对，可信度见 §5.2）——用户侧无感知，纯粹是 NAS 侧微省电。
- **结论：VPN 使用体验与内网 MTU 决策完全正交。**

### 6.3 内网开发机（M4、PVE）

- **Mac ↔ M4**：两台 X520 + DAC 同款硅、最小跳数，是 2034 档候选实验链路（Task 1 §7）；但 M4 侧能力**未经实测**（推断同 2034 封顶，无 SSH 授权）——需要用户在 M4 上执行 `networksetup -listvalidMTURange`（GATE-1 #3）才可纳入 jumbo 域。若成立，收益形态同 6.1（开发机间流量以大块编译产物/同步为主，方向同）。
- **PVE（.103/.104 为其 VM，宿主机不明）**：物理网卡与上联路径均为盲区，无任何能力数据；仅有的结论是"NAS↔PVE 的 9000 子路径**可能**成立"（Task 3 总体预判，前提 PVE 网卡支持）。**诚实结论：场景无数据，评估不可得，需先补探测。**
- PVE 经哑交换机上联（plan 侦察事实）——与 Mac 同路径，哑交换机判据已由 E1 实测否决（1518B），**换机前 PVE 侧 jumbo 子路径同样不可用**（8972 档 FAIL 已留档，`docs/network/data/task-5-exp-a1-edge-a3.txt`）。

### 6.4 备份同步

该场景本身不引入独立受益面——按流量路径映射，落到前两档结论：走 Mac↔NAS 链路的备份（大块顺序 IO）→ 同 6.1（2034 档低个位数，夜间批量任务对时延不敏感，收益意义进一步缩水）；走公网/VPN 的同步 → 同 6.2 零吞吐收益；NAS 常驻后台任务（qb/frp 等，构成 10.1% 本底 busy）与备份叠加时，包开销下降对 NAS busy 仅有 H3 同款的小幅机理贡献。**结论：不值得为备份场景单独驱动 MTU 变更，收益随附于 6.1。**

---

## 7. GATE-1 实验结果（E1）

> 执行：2026-10-12 12:32–12:56 ｜ 详细报告：`task-5-exp-report.md`（193 行）｜ 原始数据：`docs/network/data/task-5-exp-*`（19 个）｜ 变更纪律：Mac 全程零配置变更（无 root 设计）；NAS 侧全生命周期仅 eth0 MTU 一项变更，「快照→变更→验证→回滚→再验证」两轮闭环（数据：`task-5-exp-a1-2034.txt` / `task-5-exp-a1-rollback.txt`）。

**GATE-1 决议背景**（progress ledger）：用户批准全部实验（A1+A2+A3）立即执行，并口述确认物理拓扑（NAS 10G 口接哑交换机、与 Mac 同台——主路由 LAN 桥不在 Mac↔NAS 路径）；三项低成本优化（§10）纳入 Task 6a。Mac 无免密 sudo（`sudo -n` 需密码）→ 实验分两段：**E1**（纯 NAS 侧变更，透传判定以 Mac RX 计数器证据链，无需 root）+ **E2**（Mac 侧，待用户手动 sudo；后因 A1 结论取消，见 §7.3）。

### 7.1 A1：哑交换机透传判定——1518B 硬阈值，2034 档不可行

**方法演化（差分法 → 置底法）**：首轮 `ping -M do -s 2006` DF 差分被背景流量淹没（Mac ΔIpkts=2,543 ≫ 目标信号 ~100，ICMP echo 计数纹丝不动）；校准轮（idle 基线 ~48 pps + 1464B 阳性对照自证 ICMP 计数链）与交错统计轮（组间差异主要是 NAS 常驻 BT 出向 1.4–2.5MB/s 的背景突发）均不可用；`ping -i 0.002` 被内核 floor 至 10ms。**最终采用 UDP 洪泛置底法**：NAS `iperf3 -c .120 -u -b 300M -t 2 -l 2006 --dont-fragment`——2s 内 37,375±4 包 / 71.5MB，信噪比 ~200:1（vs 背景 ~0.3MB）。

**置底判定（三向锚定）**：

| 证据线 | 数据 |
|---|---|
| NAS 出门 | sender 三轮全 71.5MB / 37,375±4 包 / 0% loss；`OutPackets`/`OutOctets` 同步增长（71.7–86.5MB 含背景）→ 帧确实提交 DMA 出网卡 |
| Mac 入栈 | ΔIpkts=314 ≈ 背景；ΔIbytes=115,833/69,879/152,895（全量 ~76MB 的 ≤0.2%）→ **2034 帧的信息量在 Mac RX 完全缺席** |
| 驱动层 | `netstat -I en11 -d` **ΔDrop=0**（帧若到达 X520 被驱动以长度错误拒绝应留痕——没有）→ **丢弃发生在线路环节（哑交换机）** |
| 阳性对照 | 同法 1400B payload 53,664 ≈ sender 53,554 **精确入栈**——方法学与 ≤1518B 帧上 RX 计数链自证有效 |

**边界悬崖（二分，以太帧含 FCS = payload + 46）**：

| payload (B) | IP 包 | 以太帧(含 FCS) | Mac ΔIpkts | 判定 |
|---|---|---|---|---|
| 1400 | 1428 | 1446 | 53,831 | **PASS**（阳性参照，77.48MB 全量到达） |
| **1472** | 1500 | **1518** | **17,103** | **PASS（最高通过档；17,103 包/25.8MB 全量到达）** |
| **1473** | 1501 | **1519** | 168 | **FAIL（单字节悬崖）** |
| 1474 / 1476 / 1480 / 1490 / 1494 | 1502–1540 | 1520–1558 | 111–276 | 全 FAIL |
| 1572 / 1800 | 1600 / 1828 | 1618 / 1846 | 248–284 | FAIL |
| 2006 | 2034 | 2052 | 184–630 | FAIL（3+2 轮一致） |
| 8972 | 9000 | 9018 | 18 | FAIL（9000 档留档，PVE 判据） |

**= 哑交换机最大转发帧 1518B（802.3 标准帧），零 jumbo / baby giant 能力，硬阈值非渐变**（1618–2034 区间未逐字节扫描，无碍结论——1473 单字节悬崖已证明为硬阈值）。

**残余不确定性（置信度「高但非绝对」）**：主判读=哑交换机丢帧，依据三线——(a) >1518 即丢与 802.3 无 jumbo 交换机行为一致；(b) Mac Ierrs 与 Drop 全程零增量；(c) 阳性轮证明 RX 计数链精确可靠。但 E1 无 root 设计**无法完全排除**「Mac X520 RX 侧硬件长度上限跟随 en11 MTU=1500 静默截断且不计任何计数器」的替代解释（协议原版 P1「先动 Mac MTU 再以 NAS `InJumboPackets` 判定」正是为消此歧义——需 Mac root，属被取消的 E2 段）。两个解释对研究决策等效（2034 档端到端不可用），但影响**修复后的复测责任归属**——已记录一次性甄别法（GATE-2 议题）：**更换交换机前先按 task-5-report §2.1 P1.2 原版（Mac MTU 2034 + NAS `InJumboPackets` 计数）复测**，可将二者一锤定音。

**结论与修复路径（E1 §2.6）**：内网 2034 档当前不可行——哑交换机是唯一且决定性的短板（端点 Mac 2034+/NAS `maxmtu 16334` 就绪）；修复 = 更换支持 **≥9018B** 帧的交换机（非网管即可，本拓扑无需管理面；≥9018 为 PVE/M4 未来 9000 判据保留余量），换机后按本报告 §9 协议 A1 序列复测（Mac 侧 InJumbo 归因链已在 task-5-report §2.1 就绪）。

事故留档（方法演化的一部分，数据保留）：`-l 2022` 使 IP 包 2050>2034 的 EMSGSIZE 换算错（v1，内核出门前拒发零副作用）；verdict v1 无效轮（iperf3 server 提前被 kill、探测零发出；v2 加 `nc -z` 存活预验）。全量偏差清单见 task-5-exp-report §六。

### 7.2 A3：PMTUD 兜底探测（E1 窗口内完成）

- **NAS(2034)→Mac DF 1800**：20/20 静默丢失；Mac `netstat -s` ICMP `calls to icmp_error` 差分仅 1（背景级）、无 too big/frag 类回应——**超限 DF 在哑交换机处无 PMTUD 兜底**（丢弃点为哑 L2 设备、不产生 ICMP），有线 jumbo 域的超限 DF 单向风险面明确；实测与 §4.3 敞口并存（MSS clamp 缺失下 TCP 依赖端自身 PMTUD）。
- **NAS→公网 DF 1828**：被本机路由层拒绝（`local error: message too long, mtu=1500`；`ip route get` 显示 cache **mtu=1480** 的历史 PMTU 锁）——**公网方向 DF 大包不出网卡即被拦，无跨网黑洞**。数据：`task-5-exp-a3-pmtud-public.txt` / `-public2.txt`。
- 混档管理面（NAS 2034 / Mac 1500）下 SSH/TCP 全程正常——升 MTU 不杀既有连接的安全网得证。

### 7.3 A2：SKIPPED（中断）／ E2：CANCELLED（零信息量）

- **A2（GSO 负对照）SKIPPED**：临时副本容器 `mihomo-gso-off`（macnet `.251`）启动序列存在缺陷——配置注入未完成即 `docker start`，OpenWrt 镜像原装 lan `192.168.1.1/24` 与默认服务集（dnsmasq/odhcpd/RA 类）在 macnet 广播域（=家庭 LAN）出现裸奔窗口，引发用户可感知网络扰动，立即回滚。**零 workload 数据产出；生产容器零写入**（仅 `docker exec` 只读 + `docker cp` 读出方向）。H6 后半/H7/H8（mihomo 腿 GSO 运行时确认）维持未验证。补做条件（GATE-2 议题，三选一）：镜像预烘焙（`docker cp` 配置 + 改 .251 + `docker commit`，零裸奔窗口）／ 自定义 entrypoint 先禁原装网络服务 ／ 独立 bridge + NAT（判读时注记非完全等价）；另需 workload 源授权（`__up` 容量风险，VPS 接收端需 GATE 后写授权）。
- **E2（Mac 侧 MTU 2034 对照）CANCELLED**：A1 置底判定哑交换机 1518B 以上全丢——Mac 升 MTU 后端到端行为与 1500 无差异（帧仍止于交换机），P3 A/B 将全部等于基线（零差分零信息量），且引入不必要的 Mac root 变更风险；**交换机短板修复后自动恢复意义**（换机后 E1'（交换机透传复测）→ E2 → P3 A/B 全链条恢复）。

### 7.4 实验中断事件与网络恢复（透明度存档）

A2 预检（`.251` ARP 双侧无冲突 + 生产容器 inspect 存档：零卷挂载、mihomo 运行时配置全在容器可写层）与副本 `create` 之后，配置注入链路三次工具性失败（busybox tar 无 `--exclude`、`docker exec` 无 `sh -c` 包裹时参数解析异常）拖延了节奏；~12:56 用户报告网络异常 → 紧急回滚（容器已被父会话抢先删除；宿主 `/tmp` 清理；`eth0=1500` 复核；Mac 侧默认路由/ping `.1/.3/.2`/DNS/直连与代理出口全链核验通过）。随后实验会话 provider Connection error 断线，报告完成于恢复后的纯写作段（禁网变更）。遗留：① 污染确切机理（DHCP offer 192.168.1.x 抢答 / IPv6 RA 劫持 / mDNS 反射）未及取证即被清理，列为最可能候选；② RA 残留理论老化期（各设备 v6 默认路由 lifetime ≤30min）已过，若家庭设备 v6 出网长期异常再回查。变更纪律台账与全时间线见 task-5-exp-report §一/§五。

---

## 8. GATE-1 待决问题（向用户提问清单·v2 更新）

> **决定性问题已关闭**：Mac↔NAS 物理 L2 路径已由用户在 GATE-1 人工确认——**NAS 10G 口与 Mac 同接哑交换机，主路由 LAN 桥不在路径**（traceroute/ARP 无法分辨的项，用户口述闭环）；连带推论「主路由 br-lan 1500 封顶 2034」判据移除。剩余提问与 E1 产出的 GATE-2 新议题并列如下。

| # | 缺口 | 状态（v2） | 建议补齐方式 |
|---|---|---|---|
| 1 | ~~Mac↔NAS 物理 L2 路径~~ | **已关闭**（GATE-1 用户人工确认；连带 A1 判据链前置项解除） | — |
| 2 | 主路由 SKU 具体型号（小米万兆 BE10000/RC01 为推定） | 仍待——但影响面缩小：LAN 桥既不在路径，其 jumbo 相关性收敛为零，仅余跨界（WAN/Wi-Fi）规格核对价值 | 用户口述 / 米家 App / 授权后台 |
| 3 | `.4`（M4，同款 X520）MTU 上限与可达授权 | 仍待——Mac↔M4 是 2034 档候选链路，换机后需要 | 用户在 M4 上执行 `networksetup -listvalidMTURange` 或授权 SSH |
| 4 | UGOS Pro 版本号（≥1.0.0.0888 才有 GUI 9000；CLI 不可见） | 仍待——E1 用 CLI 未受阻，仅影响落地期 GUI 路径 | 用户读 UI 关于页 |
| 5 | VPN 出口 ~130Mbps 的归属（VPS 线路 / PPPoE / 移动侧） | 维持（GATE 后可选；E1 未触及） | VPS 侧 iperf3 server（需授权）或换 VPS 对照 |
| 6 | 背景隧道流量归因（~2Mbps：qb 容器/其他设备） | 维持——E1 侧证其影响：NAS 常驻 BT 出向 1.4–2.5MB/s 是差分法失败根因之一 | 按现状接受（推荐，含噪基线更贴近真实收益） |

**GATE-2 新议题（E1 产出，task-5-exp-report §七）**：① 哑交换机型号确认（用户口述/购买记录——本判定纯行为学，1518 硬阈值）；② 丢弃位归因的最终甄别（若用户选择跳过换机直接质疑判定：一次性 Mac 2034 + NAS `InJumboPackets` 复测，§7.1）；③ A2 补做授权（三选一加固方案 + workload 源）；④ 换机采购阈值建议（≥9018B 帧支持、非网管即可）；⑤ A3 IPv6 尾巴（可选低优先）。

---

## 9. GATE 后实验设计摘要（task-5-report A 部分协议浓缩版·含 E1 执行状态）

共同前置：实验档位**固定 2034**（9000 全档在本栈不成立）；用户在场 + 低峰窗口 + 本基线做对照 + 每步带回滚。四组协议（**执行状态**：A1 已执行于 E1——因 Mac 无免密 sudo，macOS 端步骤延后，观测方式演化为 UDP 洪泛置底法，结果见 §7；协议原貌保留，供换机后 E1'/E2 复用）：

**A1：LAN jumbo 2034 实验协议**（已执行于 E1，详见 §7）——P0 前置（拓扑确认 / 备用管理通道：Mac Wi-Fi 或 en7 + NAS 侧 shim `.250` SSH 保持打开 / 基线重放 ±8% 噪声带内 / 快照留存含 `InJumboPackets` 零值）。

P1 探测序列（判中间链路，归因靠计数器，判据先行）：

| 步 | 动作 | 判读 |
|---|---|---|
| P1.1 | Mac：`sudo /sbin/ifconfig en11 mtu 2034`（**临时性**，重启/重插即回滚，不写配置描述文件） | `ifconfig` 复核；ping .1/.2/.3 通；网页能开 |
| P1.2 | Mac：`/sbin/ping -D -s 2006 -c 10 192.168.31.3`，同步 NAS 前后取 `ethtool -S eth0 | awk '/InJumboPackets/…'` | **ΣInJumbo 增量 = 发包数 → 中间链路（已确认：仅哑交换机，§1.2）透传成功**；增量 0 → 中间丢弃（2034 不可行，跳 P4 回滚，**无需动 NAS 即完成归因**） |
| P1.3 | 同法对 `.2`/`.4`（若 M4 侧同设） | 各路径判定；`.2` 若要 2006 通过须容器 eth0 已在 2034 |
| P1.4 | 阴性对照：`ping -D -s 1472` 期间 ΣInJumbo 应仍为 0 | 防 InJumbo 计数阈值异常（阳/阴对照法） |

P2 变更序列（每步：改动 → 验证 → 观察 60s → 回归清单）：

| 步 | 变更 | 回滚 |
|---|---|---|
| P2.1 | Mac en11 → 2034 | `ifconfig en11 mtu 1500` |
| P2.2 | NAS `ip link set eth0 mtu 2034`（升 MTU 不杀既有 SSH 连接，已先行验证） | `ip link set eth0 mtu 1500` |
| P2.3 | 核对链（只读）：容器 eth0/br-lan、shim 实际值——**预期不自动跟随**，这是 macvlan 跟随机制文档结论的落地验证点 | 只读无回滚 |
| P2.4 | 容器 eth0 + shim → 2034 | 容器内复位 / `docker restart immortalwrt` 兜底（镜像默认全 1500） |
| P2.5 | 容器 br-lan → 2034（**最高风险步**，GL.iNet 锁死先例；备用通道先行确认） | `ip link set br-lan mtu 1500` / `docker restart` 终极回滚 |
| P2.6 | 双向 DF 复验（Mac↔NAS、Mac↔.2）+ ΣInJumbo 对账 | 100% 回包 |

P3 A/B 对照全套基线重放（**判读锚点**：吞吐持平≠下降、pps 490k→~360k、iperf 内建 `remote` 主口径较 44.6%/61.8% 基线相对下降即 H3 方向成立）；P4 逆序回滚 + 终验（Wi-Fi 设备回归清单 + 终止条件：任何设备失联 >60s、mihomo crash、吞吐劣化 >30% 即触发全量回滚）。

**A2～A4：**
- **A2：GSO 负对照（H6 后半/H7/H8）【SKIPPED——E1 中断跳过，零数据产出；GATE-2 补做条件见 §7.3】**——原设计：临时第二容器实例 `.251` 注入 `QUIC_GO_DISABLE_GSO=1`（不动生产 `.2`，预检 ARP 无冲突后同参复制镜像），与 `.2:7890` 交错各 3×55s 对比；**含上行 workload 补步**（env 只作用于 mihomo 发送出口，下载场景出向以小帧为主，需 `curl -T` 上行大文件补覆盖）；off 侧吞吐降或 CPU 升即证 GSO 是效率支柱、MTU 不是；若 env 无差异标记 fork 路径未生效，转 pcap 时间戳形态法（off 期下行 gap 应从双模退化为单簇）。
- **A3：混合 MTU 黑洞验证【部分执行于 E1】**——已测（§7.2）：NAS→Mac 超限 DF 静默丢失（哑 L2 无 ICMP 兜底）、NAS→公网 DF 被本机 PMTU cache 1480 拦截（非跨网黑洞）。未触及：G1 有线(2034)↔Wi-Fi 跨界探测与 G3 TCP 软启动/挂起观察（随换机后再评估）；G2 原设计（首跳 `.2` 应产 ICMP need-frag——Mac 侧 2006 DF 出网方向）因 E1 无 root 未测。
- **A4：采样规范**——§3.3 CPU 口径 + mihomo pid 动态解析 + idle 参照窗 + pps 收紧配对规则 + 噪声带（LAN ±8% / VPN ±9%）+ 形态证据标注腿归属 + 临时进程核验输出落档。

**H1–H8 判读表**（只读部分已判，其余待 GATE；E1 未执行 A/B 与 GSO 对照，H1–H8 判读状态不变——2034 档 A/B 待换机后，task-5-report §三）：

| # | 假设 | 只读判读 | 判据要点 |
|---|---|---|---|
| H1 | jumbo 前后 hy2 吞吐不变 | 基线就绪（130.8/131.0） | \|Δ\| ≤ 3% |
| H2 | 隧道协议腿 CPU 不变 | 锚点就绪（21% 单核） | on/off 分层 ≈ 0 |
| H3 | LAN 第一腿容器 CPU 降 2–5%（2034 档） | 本底就绪 + 瓶颈形态确认 | 主口径相对降幅；pps 12.4k→9.0k |
| H4 | Mac 系统代理路径 \|Δ\|≈0 | 前置不成立（桌面 mihomo 未运行）；替代证据：双路径等价 0.2% | GATE 后拉起桌面 mihomo 补对照 |
| H5 | QUIC 众数两档均 ~1452 | **前半通过**：众数 1443、>1452 = 0 | jumbo 后复拍仍 1443 |
| H6 | GSO 实际生效 | **前半通过**：ethtool 三处 on + VPS 发送腿双模 gap | mihomo 腿待 A2 负对照 |
| H7 | 禁 GSO 显著劣化 | 设计就绪 | off 侧吞吐降/CPU 升 |
| H8 | fork 保留 env 生效路径 | 只读不可验 | 与 H7 合并；无效转 pcap 形态法 |

---

## 10. 低成本无风险优化项清单（不动 MTU 即可做）

以下三项均**独立于本研究的既有问题**，不依赖 GATE 决策，可与实验解耦先行（**GATE-1 决议：三项已全部纳入 Task 6a 落地范围**，progress ledger）：

1. **QUIC buffer 核对（容器 netns）**：quic-go 启动时尝试 `SO_RCVBUFFORCE`（特权容器一般可），失败则受 netns 上限钳制。核对容器内 `sysctl net.core.rmem_max` ≥ 7MB（docker 容器内该 sysctl 是否独立于宿主 netns 需实测一次，quic-go issue #3801 有先例）；服务端 4×VPS 已 64MB 无需动作（Task 4 R7-6 / Task 2 C2）。
2. **桌面 mihomo 常驻状态核对**：背景描述为 pm2 管理常驻，但两个时点实测均未运行（pm2 空表、系统代理 disabled，Task 1 §2 / Task 5 §1.5）——若预期是常驻，核对 pm2 配置/开机自启；它同时是 GATE 后 H4 对照实验的前置（Task 4 R7-10 / H4）。darwin 侧可选 `kern.ipc.maxsockbuf` 提到 7MB（quic-go docs 建议，Task 4 R7-10）。
3. **fw4 `mtu_fix` nft 未生效修复**：现状为"配置存在、规则 0 条"（wan zone 无接口，§4.3）。基于报告证据的建议（实施前自行验证）：使 fw4 对出网 TCP 生成 TCPMSS clamp，可考虑在 lan zone 出向启用 `mtu_fix`（语义上覆盖 lan→出向转发，OpenWrt 文档级能力，Task 3 R5）或手写 nft TCPMSS 规则；收益是给跨 1480 公网路径的 DF 大包 TCP 提供黑洞兜底（现网 1500 下同样受益）。注意它只救 TCP，QUIC/UDP 仍靠 DPLPMTUD。
4. 附注（防误调优）：hy2 `bandwidth up/down`（Brutal）在当前栈**不可用**——服务端 `ignoreClientBandwidth: true` 且 mihomo 出站强制 BBR（源码级确认，Task 4 R7-4）；设了也不参与拥塞控制，误设过高反而是官方明示的反模式。`experiment.udp-gso`（yaml）是 mihomo UDP relay 开关，与 QUIC GSO 无关（QUIC GSO 唯一关闭路径是 `QUIC_GO_DISABLE_GSO` env）。

---

## 11. 附录

### 11.1 六份详细报告与数据文件的对应关系

六份详细报告（五份研究 + E1 实验）+ review/fix 记录位于 SDD workspace（git-ignored，主工作区本地保留）：

| 报告 | workspace 路径（相对仓库根） | 对应数据（`docs/network/data/`，随本报告入 git） |
|---|---|---|
| Task 1 内网拓扑与能力矩阵 | `.superpowers/sdd/jumbo-mtu-research/task-1-report.md`（+ task-1-review.md） | task-1-*（13 个） |
| Task 2 容器与 VPN 数据面 | `.superpowers/sdd/jumbo-mtu-research/task-2-report.md`（+ task-2-review.md） | task-2-*（13 个） |
| Task 3 jumbo 技术可行性（文献） | `.superpowers/sdd/jumbo-mtu-research/task-3-report.md`（+ review + rereview） | 无（引用内嵌） |
| Task 4 hy2/QUIC/mihomo 源码研究 | `.superpowers/sdd/jumbo-mtu-research/task-4-report.md`（+ review + rereview） | 无（引用内嵌） |
| Task 5 基准设计与只读基线 | `.superpowers/sdd/jumbo-mtu-research/task-5-report.md`（+ review + rereview ×2） | task-5-*（30 个） |
| E1（GATE-1 实验）LAN 透传判定 | `.superpowers/sdd/jumbo-mtu-research/task-5-exp-report.md`（§五 时间线 / §六 偏差清单） | task-5-exp-*（19 个） |

workspace 另含 `progress.md`（ledger）、`data/`（与 `docs/network/data/` 同源，75 个）、各 task-brief.md。**PR 合并后**：75 个数据文件（56 研究 + 19 实验）与 ledger 随分支进入 git；六份详细报告因 `.superpowers/` 被 ignore 不随 PR 流转——本报告 §1.4/§11.1 的映射表 + 各节「Task N §x / E1 §x」标注即为 PR 内数据 ↔ 详细结论的检索入口；如需永久保留详细报告副本，应另行归档（超出本研究范围）。

### 11.2 复现命令索引（核心项；全量见各 task 报告附录）

```bash
# 能力与拓扑（Task 1 附录 A）
networksetup -listvalidMTURange en11                      # → 1280-2034（驱动硬上限）
/sbin/ping -D -s 1472 -c 3 192.168.31.3                    # DF 探测（>1472 需先提本机 MTU）
# 容器/VPN 数据面（Task 2 附录）
ssh root@192.168.31.3 'docker exec immortalwrt nft list ruleset | grep -ciE "mss|mtu"'   # → 0（clamp 未生效）
ssh root@192.168.31.3 'ping -M do -s 1452/1453 45.202.255.241'                            # 公网 PMTU 1480
# LAN/VPN 基线（Task 5 附录 A；round 窗配对规则与 mihomo pgrep 动态解析见该附录钉死条款）
iperf3 -c 192.168.31.3 -t 10 -J                           # 单/4 流×5 取中位；-R 反向（retransmits 真值在反向）
curl -s -m 55 -o /dev/null -w '%{speed_download}\n' https://proof.ovh.net/files/1Gb.dat # VPN 双路径同法（-x 变体）
# QUIC/GSO（Task 5 B3/B4；VPS 侧）
ssh root@103.112.1.197 'timeout 70 tcpdump -i ens3 -c 500 -w /tmp/q.pcap "udp portrange 20000-30000"'  # 众数 1443
ssh root@192.168.31.3 'ethtool -S eth0 | awk "/InJumboPackets/{s+=$2} END{print s}"'     # 换机前一次性甄别 / 换机后 2034 归因计数器
# E1 置底判定与 PMTUD（task-5-exp-report §2）
ssh root@192.168.31.3 'iperf3 -c 192.168.31.120 -u -b 300M -t 2 -l 2006 --dont-fragment'  # 2034 帧 → Mac RX ≈0（丢交换机）
netstat -I en11 -d                                        # Drop/Ipkts 差分（置底三向锚定之一）
ssh root@192.168.31.3 'ping -M do -s 1800 -c 20 192.168.31.120'                          # A3：超限 DF 静默丢失
```

注意（工具坑，Task 1/5 实录）：Mac 的 PATH 首 nix GNU ifconfig/ping 与系统版本行为不同，须用 `/sbin/ifconfig`、`/sbin/ping`；容器 BusyBox ping 无 `-M do`；NAS 无 tcpdump（抓包 vantage 用 VPS 侧等价替代）；`speed.cloudflare.com/__down` 大文件被拒（改 OVH 源）。

### 11.3 研究过程 ledger 摘要（progress.md）

- **流程**：SDD 子代理驱动，全部数据采集与探测只读授权；Task 1/2 并行（不同数据源）→ 3/4 并行（文献/源码）→ 5 依赖 1–4；每 task 经 reviewer 专项审查 + fix loop 后关闭。Task 1 首次 dispatch 因 provider 网络故障（连接错误）无产出，原配置 respawn 一次成功。
- **review 要点**：Task 3 两个 I 级 finding（TB 适配器 9000 表述与本机 X520/2034 实测冲突；"不依赖路由器"拓扑前提错误——修正为"LAN 桥在路径上待确认 + 移交清单补物理确认项），Task 4 两个 I 级（收益未吸收 2034 硬上限高估 ~4×；证据版本 v1.19.27 vs 运行版 v1.19.32 一致性注记），Task 5 三个 I 级（retransmits 0 无据→N/A+反向真值；CPU 口径 2× 差异→钉主口径；GSO 腿归属+上行补步）——全部在 fix 轮闭环并已体现在本报告。
- **保留的 minor/观察项**（不阻塞结论）：Task 1 deferred ×5（证据等级措辞、Slot 3 映射未落盘、`.250` 早期猜测已被 Task 2 推翻、一处 typo、mDNS 设备名 PII 不入正式报告）；Task 2 deferred ×4（premium NAT 表述不全、ansible 变量名转述、mssclamp.txt 占位注释、桌面 mihomo 版本未实测）；Task 5 观察：iperf `remote_total` 轮间 ±6pp 散布 → 判读必须 5 轮中位对中位；数据文件一处段落标签笔误已按原始记录保留并注记（`docs/network/data/task-5-gso-check.txt`）。
- **现场发现（运维侧，未处理）**：vpn_premium 存在 2026-09-12 起的陈旧 hysteria 2.7.1 进程（不持 `:20000`，活跃 server 为 systemd v2.13.0）建议清理；NAS 上 frpc 容器有周期性 crash-loop 迹象（构成 VPN 基线背景噪声的一部分）。
- **v2 段（GATE-1 → E1 → 本更新）**：v1 报告经 adversarial final review CLEAN（0C/0I/7M，17 关键数字三层链核对通过）并 commit（64e246f）；GATE-1 PASSED——用户批准全部实验 + 拓扑确认（NAS 同台哑交换机）+ 三项低成本纳入 Task 6a；E1 执行：A1 置底判定哑交换机 1518B 硬阈值（2034 档不可行）、A3 PMTUD 双向探测完成，A2 因副本容器裸奔事故 SKIPPED、E2 因 A1 结论 CANCELLED；实验会话 provider 断线 + 网络扰动由父会话急救恢复。残余不确定性（Mac RX 替代解释）与一次性甄别法入 GATE-2 议题（§7.1/§8）。

---

*本报告 v2 = 研究阶段（Task 1–5）合成稿 + GATE-1 实验（E1）结论并入。当前状态：内网 2034 档不可行（哑交换机 1518B 硬阈值）——待 GATE-2 裁决：换机评估（型号 / 丢弃位甄别 / ≥9018B 采购阈值）、A2 补做、Task 6a 低成本修复落地。*
