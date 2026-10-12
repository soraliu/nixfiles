# 内网 Jumbo MTU 落地方案(Task 6a · GATE-2 评审稿)

> 编写:2026-10-12 | 状态:**待 GATE-2(用户 approve)** — approve 后 Task 6b 照本文档执行
> 输入材料(全部已定稿):`docs/network/jumbo-mtu-research.md`(研究 v2,下称「研究报告」)、`docs/network/switch-research.md`(下称「switch-research」)、`.superpowers/sdd/jumbo-mtu-research/task-{2,4,5,5-exp}-report.md`(下称 Task 2/4/5/exp 报告)、`docker/immortalwrt/`(现有 infra 代码)、`plan/jumbo-mtu-research.md`(SDD 计划)
> 溯源约定:所有断言标注来源(如「研究报告 §4.3」「Task 2 §A4」);本文档不引入输入材料之外的新事实;推断性内容显式标注【推断】。命令均为可复制执行级。

---

## 0. 方案总览

| 轨道 | 内容 | 执行时机 | 依据 |
|---|---|---|---|
| **A. 立即执行(无风险)** | a) fw4 MSS clamp 修复(唯一代码变更项,nixfiles PR);b) mihomo 常驻核对(c/b 双视角,预期零改动或轻改动);c) 4×VPS 服务端 QUIC buffer 与配置核对(纯只读) | GATE-2 approve 后低峰窗口 | 研究报告 §10(三项低成本清单,GATE-1 已决议纳入 Task 6a) |
| **B. 用户采购决策(非本 plan 执行)** | 更换支持 ≥9018B 帧的交换机;首推绿联 CM996(¥1499);下单前可选做 Mac RX 一次性甄别实验 | 用户自行决策 | switch-research 全文 |
| **C. 换机后启用指引(预案文档)** | Mac en11 2034 + NAS eth0 + macvlan 链路的启用/验证/回滚序列(浓缩自 task-5-report A1 协议) | **B 轨道完成后执行** | E1 §2.6、task-5-report §2.1 |

**决策链位置**:研究结论——内网 2034 档当前不可行(哑交换机 1518B 硬阈值,E1 §2.4),9000 全档在本栈不成立(Mac X520 驱动上限 2034,Task 1 §1),VPN 与 MTU 解耦零收益(研究报告 §4.4/§5.2)。因此本 plan 动作收敛为:① 修既有独立缺陷(轨道 A);② 用户采购解锁 2034 档(轨道 B);③ 换机后按预案启用(轨道 C)。**本 plan 不含任何 VPN 链路的 MTU 变更**。

---

## 1. 落地范围(分轨)

### 1.1 轨道 A:三项低成本优化(立即执行,不依赖换机)

> 三项均独立于 jumbo 研究结论、修的是既有缺陷(现网 1500 下同样受益),GATE-1 已决议纳入 Task 6a(研究报告 §10)。

#### A-a fw4 MSS clamp 修复(本 plan 唯一代码变更项)

**缺陷现状**(报告三处一致):容器 UCI 中 wan zone `mtu_fix='1'` 配置存在,但 `nft list ruleset` 3994 行中 mss/mtu 规则 **0 条**——当前全网无任何 MSS clamp;公网 1480 路径实测为 DF 黑洞(1453+ 无 ICMP 回执),跨网 TCP 仅靠端自身 PMTUD 兜底,QUIC/UDP 靠 DPLPMTUD(研究报告 §4.3,Task 2 §A4)。

**根因诊断**(Task 2 §A4 + 现有代码对照):wan zone 绑定的 `network='wan' 'wan6'` 接口在本容器中不存在——`docker/immortalwrt/Dockerfile` 构建期执行了 `uci delete network.wan; uci delete network.wan6`(旁路由拓扑只保留 br-lan 静态 .2),wan zone 因此成为无接口的空 zone,**fw4 不为空 zone 生成 TCPMSS clamp 规则**。「配置存在 ≠ 规则生成」正是本缺陷的隐蔽之处。

**修复路径选择**:三条候选,推荐路径 1。

| 路径 | 方案 | 评估 |
|---|---|---|
| **1(推荐)** | `uci set firewall.lan.mtu_fix='1'` — fw4 为 lan zone 的 forward(转出)路径生成 TCPMSS clamp(动态 clamp 至路由 MTU,fw4 文档级能力,研究报告 §10.3 建议) | ✅ 一行 uci、零手写规则;fw4 每次重载自动重建规则,无维护面。旁路由容器是**单 zone 拓扑**(仅 lan),所有经它 L3 转发的流量都从 lan 进,语义上恰好等于「lan→出向全量 clamp」 |
| 2(备选) | 手写 nft 规则(fw4 `config include` type nftables),固定 clamp MSS 1460 | 备用于路径 1 生成形态不符时(见 §2.2 的规则文本) |
| 3(否决) | 在 nikki/tproxy 链上补 clamp | ❌ **位置错误**:tproxy 链挂 prerouting 拦截 Mac→公网流量进 mihomo(第一腿终止于 input/mihomo socket,不过 forward 链);在此 clamp 会压掉 **LAN 第一腿 MSS**(tproxy 只救 TCP,clamp 它反而让通告 MSS ≤1460)——第一腿在 LAN 内部,无需降档,且未来 2034 档时该腿的 MSS 是研究报告 §4.2/§5.1 中 mihomo 容器 CPU −2~5% 收益的机理来源,clamp 它=自毁收益。真正需要 clamp 的是 **bypass 直连流量**(不被 tproxy 拦截、走 forward 出网的 TCP,如国内直连),而那正是路径 1 的覆盖面。【推断】:「bypass 流量不进 tproxy 而以普通 forward 出网」基于 `nikki.proxy.bypass_china_mainland_ip='1'` 的常规语义——nft 层 bypass 与 mihomo 进程内直连(出网走 output 面)两种实现语义不同,输入材料未实证,§2.2 判据 3 验证时一并核实 |

**nixfiles 落点**:`docker/immortalwrt/Dockerfile` §3「Configure Firewall (NAT & Traffic Rules)」节——与现有模式一致(所有容器网络/防火墙/nikki 配置全部烘焙进镜像,运行时零 touch;`default.nix` 只负责 sops 配置注入)。diff 见 §2.2。

**影响面**:
- **受扰(=受益)**:经容器 L3 转发的 TCP bypass 直连流量的 SYN(目的为公网或内网非本段设备;覆盖面成立的前提=bypass 流量经 forward 链转发——【推断】,见路径 3 备注,§2.2 判据 3 含核实步骤)——MSS 被 clamp 下限。现网全网 1500 下**行为无差异**(SYN 本来就通告 1460,clamp 后仍 1460);其价值在未来内网抬档后封住「大 MSS 出公网黑洞」敞口(研究报告 §4.3:内网 2034 后跨网 TCP 若带 MSS 1994 出 1480 公网路径即黑洞,而该路径 DF 黑洞无 ICMP 回执)。
- **不受扰**:① Mac↔NAS/M4 的 host route 直连 L2 流量(不经容器,轨道 C 的 2034/9000 档收益无损);② **VPN 第一腿**(Mac→mihomo 走 tproxy 的 prerouting→input 路径,不经 forward 链;研究报告 §4.4 的 131Mbps 基线与 §5.2 的 mihomo −2~5% CPU 前提均保持);③ UDP/QUIC(MSS clamp 只及 TCP,隧道腿靠 DPLPMTUD 自兜底,研究报告 §4.2);④ NAS 自身流量(NAS default via .1 直连主路由,不经旁路由,Task 2 §A1)。
- **与轨道 C 的交互(要点)**:fw4 生成规则的 clamp 值跟随路由 MTU(容器视角)。**若轨道 C 抬升容器 br-lan/macvlan 至 2034,对公网目的的 rt mtu 亦随之变为 2034,clamp 值将 >1452,公网兜底失效**——轨道 C 的 P3 验证中必须复核该行为(见 §1.3 风险框),必要时切换到路径 2 的固定值 clamp。

#### A-b mihomo 常驻核对(预期零改动或轻改动)

两个视角并行核对(任务原文「mihomo 容器化常驻核对」覆盖研究项 §10.2「桌面 mihomo 常驻状态核对」与容器侧健康):

**视角一:容器 mihomo(immortalwrt .2)常驻健康**——预期零改动。
现状事实:容器 `immortalwrt` Privileged / macnet / **RestartPolicy: always**,运行 since 2026-08-05(Task 2 §A2);mihomo v1.19.32 tproxy :7892 活跃,nft tproxy 链计数 232 万包(Task 2 §A5);容器与 sops 源配置结构 28 键完全一致(Task 2 §B)。核对清单+判定标准见 §2.3 表;任何一项偏离才触发容器侧动作(`just reset` 级)。

**视角二:桌面 mihomo(Mac pm2)常驻状态**——研究报告 §10.2 项:背景描述为 pm2 管理常驻,但**两个时点实测均未运行**(pm2 空表、系统代理 disabled,Task 1 §2 / Task 5 §1.5),且它同时是 H4 对照实验的前置。本 plan 核对目标是区分「模块未启用(设计行为)」与「启用但未拉起(故障)」:
- 事实基础:`home/modules/network/clash-meta/default.nix` 的 `programs.clash.enable` 默认取 `useProxy`(`flake.nix` L153 `useProxy ? false`),当前 nixfiles 全仓仅 `ide-cn` homeConfig 显式传 `useProxy = true`——【推断】Mac 的激活配置大概率未启用该模块,「未运行」是**设计行为而非故障**。
- 判定标准与两种走向见 §2.3;a) 若为设计行为 → 本项结论「零改动」,仅在 GATE-2 请用户确认「桌面端是否需要另外决策」;b) 若模块已启用但 pm2 未拉起 → 修复自启(Home Manager rebuild 层面,非容器流程)。
- 附带核对(仅当桌面 mihomo 确认常驻启用才有意义):darwin `kern.ipc.maxsockbuf` ≥ 7MB(quic-go 官方建议,研究报告 §10.2 / Task 4 R7-10)。

#### A-c 服务端(4×VPS)QUIC buffer 字段与运行态核对(纯只读 checklist)

> 边界:本 plan **只列核对命令与判定标准,不含 ansible diff**;若核对发现需要改动,走 `personal-k3s-ops` 仓库的独立 PR 流程(plan Files-to-modify 已预设另仓库另 PR)。服务端 sysctl 64MB 已就位(4 台一致,Task 2 §C2),**本项预期主流情形是全 PASS 零改动**。

核对清单(全部 SSH 只读):

| # | 核对项(命令) | 预期值(判定标准) | 来源 |
|---|---|---|---|
| c1 | `sysctl net.core.rmem_max net.core.wmem_max` | 67108864(64MB);官方建议 ≥16MB,现值远超 → 无动作 | Task 2 §C2 / Task 4 R7-1 |
| c2 | `ethtool -k <出口口> \| grep tx-checksumming` | on(GSO 前提;vpn_premium/vpn_secondary/hangzhou 顺带覆盖,三处已实证 on) | Task 4 R7-3 / Task 5 §1.4 |
| c3 | `grep -iE "StreamReceiveWindow\|ConnReceiveWindow\|bandwidth\|disablePathMTUDiscovery\|congestion" /root/.config/hysteria/config.yaml` | 窗口字段全部未显式(官方默认 8/20MB——**不调整**,2:5 比例勿破);`ignoreClientBandwidth: true` 维持 | Task 2 §C3 / Task 4 R7-2 |
| c4 | **防误调优核对(只看不改)** | 确认无人设置 hy2 `bandwidth up/down`(Brutal):服务端 `ignoreClientBandwidth: true` + mihomo hy2 出站强制 BBR,**Brutal 路径整体不参与拥塞控制,误设过高是官方明示反模式**;确认无人误改 `experiment.udp-gso`(mihomo UDP relay 开关,与 QUIC GSO 无关——QUIC GSO 唯一关闭路径是 `QUIC_GO_DISABLE_GSO` env) | 研究报告 §10.4 / Task 4 R7-4/R7-8 |
| c5 | 运维附带项(如实记录,非本 plan 执行) | vpn_premium 存在 2026-09-12 起的陈旧 hysteria 2.7.1 进程(不持 :20000,活跃 server 为 systemd v2.13.0)→ 清理属写操作,见 §4 议题 12(授权后经 personal-k3s-ops 或手动执行);NAS 上 frpc 容器周期性 crash-loop 迹象(VPN 基线背景噪声之一)仅存档 | Task 5 §1.8-3/§1.8-8 / 研究报告 §11.3 |
| c6 | 容器 netns QUIC buffer:`docker exec immortalwrt sysctl net.core.rmem_max` | 67108864(64MB)——**Task 2 §A3 已实测闭环**(容器 netns 内同样生效),本行为复感性核对;≥7MB 即满足 quic-go 建议 | 研究报告 §10.1 / Task 2 §A3 / Task 4 R7-6 |

### 1.2 轨道 B:换 ≥9018B 交换机(用户采购决策项,不属本次执行)

**为什么换**:E1 置底判定现哑交换机最大转发帧 **1518B(含 FCS)= 802.3 标准帧,1473B payload(1519B 帧)起单字节悬崖丢弃**——2034/9000 档均不透传,是端点(Mac 2034+/NAS maxmtu 16334 就绪)之外唯一且决定性的短板;修复 = 更换支持 ≥9018B 帧的交换机(非网管即可,本拓扑无需管理面;≥9018 为 PVE/M4 未来 9000 判据保留余量)(E1 §2.4/§2.6)。

**推荐**(switch-research 全文浓缩):

| 排名 | 型号 | 端口 | Jumbo | 参考价(2026-10) | 一句话 |
|---|---|---|---|---|---|
| 🥇 | **绿联 CM996** | 4×10G 电 + 4×SFP+ | ✅ 12K(官方电子说明书) | **¥1499** | 唯一端口形态完全命中(2×DAC 复用 + NAS/小米各占电口);非网管无风扇,与 NAS 同厂生态 |
| 🥈 | 兮克 SKS7300-4X4T | 4电+4光,二层管理 | ⚠️ 未声明(需客服确认) | ¥1248 | 带管理但有风扇噪音与 jumbo 证据弱 |
| 🥉 | TP-LINK TL-SX3008F | 8×SFP+ 全光,L2+ | ✅ 9KB(datasheet) | ≈¥1700–2500+模块 ¥700–1000 | 电口需 SFP+ 电模块,总成本反超 |
| ⚠️ | ~~TL-ST1008F~~ | 8×SFP+ 非网管 | ❌ 1522B 上限 | ¥675 | **陷阱勿买**——等于换个一模一样的短板 |

采购硬约束:jumbo 必须有**数值明示**(9216/9600/12K/16K);TP-LINK 官方 FAQ 明文「spec 未声明 = 最大 1522B」(switch-research §1/§3.5)。

**换机收益预期**(switch-research §9,全部为预期、实验待验证):① CPU/中断/pps 摊薄(方向确定性最高):每包成本项 ÷1.37(Mac 出向 490k→~358k pps、mihomo 容器 CPU −2~5% 相对、NAS 接收路径 4 流瓶颈形态为主要观测点);② LAN 吞吐 +0~5%(非保底,基线 6.94G 未触及 10G 物理上限);③ VPN **零增益零变化**(实证级,QUIC ≤1452 与 underlay 解耦);④ 9000 全幅档仅 PVE↔NAS 单对(MSS 8960,CPU −5~15% 潜力)。

**下单前可选:Mac RX 替代解释的一次性甄别**(E1 §2.5 残余不确定性,置信度「高但非绝对」):E1 无 root 设计无法完全排除「Mac X520 RX 硬件按 en11 MTU=1500 静默截断且不计计数器」的替代解释——两个候选解释对换机决策完全不同向,10 分钟小协议可直接二选一置底(三段式,判读见下):

```
前置:NAS InJumbo 零值快照
  ssh root@192.168.31.3 'ethtool -S eth0 | awk "/InJumboPackets/{s+=$2} END{print s}"'   # 记零值
变更(Mac,临时性,重启/重插即回滚):
  sudo /sbin/ifconfig en11 mtu 2034 && /sbin/ifconfig en11 | grep mtu                    # 复核 2034
  ping -c2 192.168.31.{1,2,3}                                                           # 连通自验
探测(Mac,发包 1000,BatchMode 顺跑):
  /sbin/ping -D -s 2006 -c 1000 -i 0.05 192.168.31.3
  # 同时 NAS 前后再取 InJumbo(同上命令),Δ = 结束值 − 零值
回滚:
  sudo /sbin/ifconfig en11 mtu 1500 && /sbin/ifconfig en11 | grep mtu && ping -c2 192.168.31.3
```

判读(task-5-report §2.1 P1.2 原版判据,InJumbo 本底为零→信噪比干净)。**预期行为备注(执行前必读)**:a) 窗口内 2006 ping 零回复属预期——回程 echo reply 需 NAS 以 eth0(仍 1500)回发 2034 帧将被本机拒发,且 Mac↔NAS 既有连接不受影响(E1 §7.2 混档实证);判据**只看 ΔInJumbo**(单向到达计数)。b) 窗口内**避免从 Mac/NAS 发起新的大流量 TCP 传输**(SMB/rsync 等):新建会话将协商 MSS 1994,大段以太帧 ~2040B 超旧交换机 1518B 阈值被丢弃致会话挂起——选低峰 + 无备份任务窗口执行:
- **ΔInJumbo ≈ 发包数** → 旧交换机在 Mac→NAS 方向实测可透传 2034(交换机转发通常对称),E1 的丢帧应改归因 Mac RX 侧(en11 MTU=1500 时拒大帧不计数的硬件行为)——**Mac↔NAS 2034 档无需换机即可进入轨道 C 启用**,重新裁决采购(是否仍换机取决于 NAS→Mac 方向与 PVE/M4 9000 判据的价值权重);
- **ΔInJumbo = 0** → 维持主判读(哑交换机丢帧),照常执行采购。
- 附带阴性对照:`/sbin/ping -D -s 1472 -c 5` 期间 InJumbo 应仍为 0(防计数器阈值异常,task-5-report P1.4)。

### 1.3 轨道 C:换机后 2034 档启用指引(预案文档,**B 轨道完成后执行**)

> 浓缩自 task-5-report §2.1(A1 协议)与 task-5-exp-report §九(遗留 TODO)。**以下内容为换机后的预案,本次一律不执行。**

**C.1 物理迁移**(switch-research §5 端口规划):Mac DAC→SFP+ P1、M4 DAC→P2、NAS AQC113→10G 电 P5、小米万兆上联→P6,余口(2 电多速率 + 2 光)留 Wi-Fi AP/IoT/PVE 万兆扩展;哑交换机退役或转纯千兆 IoT 段。即插即用无配置。迁移验证:`ping -c2` 三点互通(.1/.3/.4)+ 10G 协商速率复核(`system_profiler` / NAS `ethtool`)。

**C.2 E1' 透传复测**(置底法快版,E1 §2.3 复用;**前置 = NAS eth0 抬档**——E1 的有效执行前提是 NAS eth0 已抬至 2034,见 E1 变更纪律台账 #1;省略前置直接洪泛会得到 E1 v1 事故同款 `local error: message too long`(内核出门前 EMSGSIZE 拒发,task-5-exp-report §六-2))。复用 E1「快照→变更→验证→复测→回滚→再验证」纪律:

```
① 前置快照与基线(连通三项:ping .1/.3 双向、curl 出网 200、NAS SSH 存活——E1 台账同款):
   ssh root@192.168.31.3 'ip -d link show eth0'                       # 记录 mtu=1500 起点
② NAS eth0 抬档(2006 判据用 2034;后续 ⑤8972 判据需再抬 9000——均在 maxmtu 16334 能力内):
   ssh root@192.168.31.3 'ip link set eth0 mtu 2034 && ip -d link show eth0 | grep mtu'
   验证:读数 2034 + 连通三项复测(升 MTU 不杀既有连接,E1 台账 #1 已证)
③ 置底洪泛 ×2–3 轮(同 E1 口径,sender 每轮 ~37,375 包 / 0% loss):
   ssh root@192.168.31.3 'iperf3 -c 192.168.31.120 -u -b 300M -t 2 -l 2006 --dont-fragment'
   同步 Mac 前后取 netstat -I en11(ΔIpkts / ΔIbytes 差分)
④ 判读:
   ΔIpkts ≈ sender 包数 → 新交换机 2034 透传 PASS(全量到达);
   ΔIpkts ≈ 0 且 Mac en11=1500 → 二义(新交换机劣质 vs Mac RX 按 en11 MTU 拒收,E1 §2.5 替代解释)→ 在 Mac en11=2034 状态下再跑一轮(用户在场手动 sudo;仍 ≈0 才可归因新交换机 FAIL);
   (若 §1.2 甄别实验已做且归因 Mac RX → 本复测必须在 Mac en11=2034 状态下进行,否则 NAS→Mac 方向帧必被 Mac 拒收)
⑤ 8972 档留档复测(可选,给 PVE 判据):eth0 抬 9000 后同法 -l 8972(9018 帧),判读同上;
⑥ 回滚:ip link set eth0 mtu 1500 + 连通三项 + 1464×20 复验 100%(E1 台账闭环序列)
```
判读注意:ping 回包零到达属预期、不构成失败判据——回程 echo reply 需 Mac 以 en11 当前 MTU 回发 2034 帧(1500 下无法回发,E1 §2.1 原口径);单向到达证据只看 Mac ΔIpkts/ΔIbytes + NAS sender 0% loss。

**C.3 启用序列**(A1 协议浓缩;每步「变更→验证→观察 60s→回滚」节拍,全部命令原文见 task-5-report §2.1):

| 阶段 | 动作 | 关键判据/回滚 |
|---|---|---|
| **P0 前置** | 备用管理通道(Mac Wi-Fi/en7 + NAS 侧 `.250` shim SSH 保持打开,shim 不动 MTU);基线重放(单流×2 + VPN×1 落 ±8% 噪声带);快照留存(Mac `/sbin/ifconfig en11`、NAS `ip -d link`、容器 `ip link`、`docker network inspect macnet`、InJumbo 零值) | 缺一不可(task-5-report P0) |
| **P1 探测** | Mac `sudo /sbin/ifconfig en11 mtu 2034`(临时性)→ `/sbin/ping -D -s 2006 -c 10 .3` + NAS 前后取 InJumbo;同法对 `.2`(须容器 eth0 已 2034 方可过)/`.4`(若 M4 侧同设);阴性对照 1472 期间 InJumbo=0 | InJumbo 增量=发包数 → 链路透传成功;回滚 `ifconfig en11 mtu 1500` |
| **P2 变更** | ① Mac en11→2034;② NAS `ip link set eth0 mtu 2034`;③ **核对链**(只读):容器 eth0/br-lan、macvlan-shim 实际值——预期**不自动跟随**(macvlan 定值于创建时,Task 3 macvlan 节);④ 容器 eth0 + shim→2034(`docker exec` / 宿主 `ip link`);⑤ 容器 br-lan→2034(**最高风险步**:GL.iNet 锁死先例,备用通道先行确认);⑥ 双向 DF 复验 2006 + InJumbo 对账 | ② 回滚 `ip link set eth0 mtu 1500`;④ `docker restart immortalwrt` 兜底(镜像默认全 1500);⑤ 回滚 `ip link set br-lan mtu 1500`,终极 `docker restart` |
| **P3 A/B** | LAN 全套重放(单/4 流×5、30s 窗、反向×2;CPU 用 iperf3 内建主口径)+ VPN 第一腿全套 + QUIC 复拍(众数应仍 1443) | 锚点见 C.4 |
| **P4 回滚/终验** | 逆序复位全 1500 → 三处复核 → 回归清单(Wi-Fi 设备、DNS、代理出口、SMB)→ 复测回基线 ±8% | 终止条件:任何设备失联 >60s / mihomo crash / 吞吐劣化 >30% 即全量回滚 |

**C.4 收益判定锚点**(switch-research §9.2 / task-5-report §8 P3 判决线):

| 指标 | 基线(1500) | 2034 档预期 |
|---|---|---|
| Mac 出向 pps(30s 窗) | 490k | **≈358k(÷1.37,硬判据)** |
| NAS CPU(iperf3 内建 remote 主口径) | 单流 44.6% / 4 流 61.8% | 相对降 2–5%(判决线:单流 ≤~42–44 / 4 流 ≤~58–60) |
| LAN 吞吐 | 单流 6.94G / 4 流 5.68G | 持平≠下降,+0~5%(非保底) |
| mihomo 容器 CPU(VPN 满载,单核) | ≈21% | −2~5%(相对,方向可信幅度须实测定标) |
| Mac en11 入向 pps(VPN 满载) | 12.4k | ≈9.0k |
| QUIC 众数(VPS 侧 pcap) | 1443,>1452 = 0 | 不变(H5) |

**C.5 9000 档扩展(可选)**:仅 PVE↔NAS 单对(PVE = Linux X520,switch-research §9 前提注;NAS 侧 UGOS Pro ≥1.0.0.0888 起 GUI 可设 9000,**版本待核**,且有个别旧版本持久化回落 bug,Task 3)。判据:E1 已留 8972/9018 帧 FAIL 存档,新交换机上该探测 PASS 即解锁(复测时 NAS eth0 须 ≥9000,见 C.2 ⑤;E1 原轮在 eth0=2034 窗口内的发送语义已失效,以换机后重测为准);Apple 端点(Mac/M4)不参与本档。

**C.6 持久化遗留点(重要)**:C.3 的全部抬档是**运行时临时变更**——容器重启即回镜像默认 1500(`docker restart` 还是回滚手段)。若 P3 验证通过且用户决策常驻,则需后续独立需求:Dockerfile UCI `network.@device` 追加 mtu(macvlan 不支持 docker 层显式 MTU,moby issue/源码结论)+ `nas-startup.sh` 追加 shim/eth0 的 `ip link set`;**该固化不属于本 plan 与 6b 范围**,单独立项。
**轨道 A-a 的交互风险**:br-lan/macvlan 抬至 2034 后,lan zone mtu_fix 的 rt-mtu 基准随之变为 2034,对公网方向的 clamp 兜底失效(见 §1.1 影响面警示)——C.3 P3 验证中若确认 bypass 直连公网 TCP 异常(大流挂起),将 A-a 修复切换为路径 2 固定值 clamp(1460)再复验;判别口径与「黑洞 vs 慢路径」方法见 Task 3 R5(`ping -D` 全通 + 大流量挂死 = L2 黑洞)。

---

## 2. 执行顺序与 diff

### 2.1 依赖与顺序

```
GATE-2 approve(本文档)
 ├─ A-a:改 nixfiles(仅 A 轨道需要 PR)→ just build → 容器切换(低峰,~1-2 分钟停机)
 ├─ A-b:纯只读核对(可在 A-a rebuild 前后任意顺序;零停机)
 ├─ A-c:纯只读核对(与 A-a/b 并行;涉及 4×VPS SSH 只读授权沿用研究期)
 └─ (B 轨道:用户决策,随时;可选先做 §1.2 甄别实验)
      └─ C 轨道:B 完成后按 §1.3 预案(E1' → A1 P0-P4)
```

### 2.2 A-a 实施(改 nixfiles → rebuild 镜像 → 容器更新)

**前置条件**:
1. 低峰窗口 + Mac 用户在场(容器切换期间经 .2 的网关路径中断约 1–2 分钟;内网 host route 直连不受影响);
2. SSH 管理通道经 NAS(`root@192.168.31.3`,可用 .250 shim 通道),**不经 .2**;
3. 现状复核(可选,30 秒):`ssh root@192.168.31.3 'docker exec immortalwrt uci show firewall | grep mtu_fix; docker exec immortalwrt nft list ruleset | grep -ciE "maxseg|mss"'` → 预期 `mtu_fix='1'`(wan)+ `0`(规则数),与研究基线一致;若不一致,先以现状为准修订本方案。

**变更①:nixfiles PR(Dockerfile 一行)**

```diff
--- a/docker/immortalwrt/Dockerfile
+++ b/docker/immortalwrt/Dockerfile
@@ -57,7 +57,8 @@
 # Enable IP masquerading for proper NAT forwarding of subsidiary router traffic
 RUN LAN_ID=$(uci show firewall | grep "\.name='lan'" | awk -F. '{print $2}' | head -n 1) && \
     [ -n "$LAN_ID" ] && uci rename firewall."$LAN_ID"='lan'; \
     uci set firewall.lan.input='ACCEPT' && \
     uci set firewall.lan.output='ACCEPT' && \
     uci set firewall.lan.forward='ACCEPT' && \
+    uci set firewall.lan.mtu_fix='1' && \
     uci set firewall.lan.masq='1'
```

说明：wan zone 的 `mtu_fix='1'` 为基镜像默认（空 zone 不生成规则，留着无害）——**不建议**在本 diff 中顺手删除，保持最小变更；它是否清理属可选卫生项，留给后续。

可选预演（推荐，先验证方案生效再固化，避免一次 rebuild 返工）：在**运行中容器**先执行 `docker exec immortalwrt sh -c "uci set firewall.lan.mtu_fix='1' && uci commit firewall && fw4 restart"`，按下面验证节的判据 2/3 确认 nft 规则生成且流量无碍后，再落地 Dockerfile 变更与重建（预演值随后被镜像默认覆盖，无需单独回滚）。

**变更②：重建镜像**（现有 just 链，`docker/immortalwrt/Justfile`）：

```bash
cd docker/immortalwrt && just build
# 等价于三步：build-base(Dockerfile→immortalwrt-base.tar)
#            → build-config(nix + sops 解密注入 config.yaml→docker load immortalwrt:latest)
# 期间旧容器照常运行，无停机。
```

**变更③：容器切换**（两选一，推荐 A 方案缩短停机）：

```bash
# 方案 A（推荐）：预构建完成后，停机窗口=容器起机（约 30–90s）
docker stop immortalwrt && docker rm immortalwrt
just run                                  # docker run -d --name=immortalwrt --network=macnet --privileged --restart=always immortalwrt /sbin/init
# 注意：macnet 网络对象是现存的，just run 复用（不删不建）；若意外需重建才用 just create-network

# 方案 B：just reset —— stop→rm→build→run；停机窗口包含整个 build（层缓存未命中时可达数分钟+依赖外网 opkg）
```

**验证（成功判据）**：
1. 容器健康：`docker ps --filter name=immortalwrt`（Up）+ Mac `ping -c2 192.168.31.2` 通 + `.250` shim 通道 SSH NAS 正常；
2. **规则生成（核心判据）**：`ssh root@192.168.31.3 'docker exec immortalwrt nft list ruleset | grep -iE "maxseg|mss"'` → **由 0 条变为 ≥1 条**（fw4 为 lan zone 生成的 TCPMSS clamp 规则，带 mtu_fix 语义；具体链名/规则形态以 fw4 24.10 实际生成为准——若此处仍为 0，说明 fw4 对该拓扑的 mtu_fix 渲染与预期不符，转备选方案）；
3. 规则命中率：日常跑一轮 bypass 直连流量（Mac `curl -sI https://www.baidu.com` 类国内目标）后，`nft list chain` 中带 counter 的相应规则计数增长。**备选解释**：counter 无增长但规则存在（判据 2 已过）时，先核实 bypass 流量确实经 forward 链（对比 tproxy 链与 forward 链计数分布/抓包）——若 bypass 实为 mihomo 进程内直连（出网走 output 面不过 forward，见 §1.1 路径 3【推断】注），则本判据不适用于该形态，规则已生成即满足修复目标（经容器 forward 的流量均已兜底），不应误触发切换路径 2；
4. 回归：代理出口 `curl -s https://www.cloudflare.com/cdn-cgi/trace | grep ^ip=`（应仍为 103.112.1.197 / NRT，task-5-report §1.5 出口对照）；VPN 抽测一轮 `curl -s -m 55 -o /dev/null -w '%{speed_download}\n' https://proof.ovh.net/files/1Gb.dat` 对照 130.8 Mbps 基线的 ±9% 噪声带（task-5-report §1.2）；
5. **当下不进行的验证**（如实声明）：MSS clamp 的行为差异化（Syn MSS 被压）要等轨道 C 抬档后才有观测意义——现网全网 1500，SYN 本来就是 1460，clamp 无可见差异；本轮以「规则存在 + counter 命中 + 流量回归」为判定准绳。

**回滚**：
- **运行时回滚**（不动镜像，即时生效）：
  ```bash
  ssh root@192.168.31.3 'docker exec immortalwrt sh -c "uci set firewall.lan.mtu_fix=0 && uci commit firewall && fw4 restart"'
  # 验证：nft ruleset 中 mss 规则回到 0 条
  ```
  注意语义：容器内运行时 uci commit 写入容器可写层，`docker restart` 保留；只有**重建容器**（rm + run）才回到镜像默认。故运行时回滚后，下次容器整体重建时 clamp 会重新生效——彻底回滚必须走 git revert。
- **永久回滚**：git revert 本 PR commit → `just build` → 容器切换（同变更③）。
- 兜底：容器切换后网络异常 → Mac 侧网络路径不可达时，经 NAS SSH（shim 通道）`docker restart immortalwrt`；再不行 `docker logs immortalwrt` 排障（fw4 restart 为 nft 规则集重建，established 连接由 conntrack 保障，预期平滑——保守起见选低峰窗口执行）。

**备选方案（路径 2，仅在主方案规则不生成时启用）**：手写 nft include（固定值 clamp，不受容器未来 MTU 抬升影响）：
```bash
# 容器内落文件 /etc/mssfix.nft（内容如下）
table inet mssfix {
    chain forward_clamp {
        type filter hook forward priority mangle; policy accept;
        meta l4proto "tcp" tcp flags & (fin | syn | rst) == syn tcp option maxseg size > 1460 tcp option maxseg size set 1460 counter
    }
}
# 注册为 fw4 include（uci）：
#   docker exec immortalwrt uci add firewall include; uci set firewall.@include[-1].type='nftables'; \
#   uci set firewall.@include[-1].path='/etc/mssfix.nft'; uci set firewall.@include[-1].position='ruleset-post'; \
#   uci commit firewall && fw4 restart
# Dockerfile 固化：heredoc 写入该文件 + COPY 进镜像，再注册 include（模式与现有 sops config 注入并列）。
```
hook 本身限定 forward 链（不触 tproxy 第一腿），固定值 1460 保证轨道 C 抬档后公网兜底依然有效。

### 2.3 A-b 实施核对流程（只读；发现异常才进入改动分支）

| # | 核对（命令） | 判定标准 | 异常时走向 |
|---|---|---|---|
| 1 | 容器常驻：`ssh root@192.168.31.3 'docker inspect immortalwrt --format "{{.State.Status}} {{.HostConfig.RestartPolicy.Name}}" && docker ps --filter name=immortalwrt'` | `running` + `always`，Up 天数连续（基线：since 2026-08-05） | 容器 stopped/restarting → 排障 `docker logs`，必要时 `just reset`（走 §2.2 链） |
| 2 | 容器内 mihomo 健度：`docker exec immortalwrt pgrep -fx "/usr/bin/mihomo -d /etc/nikki/run" && docker exec immortalwrt /usr/bin/mihomo -v` | 进程存在；v1.19.32（nikki 自带二进制口径） | 版本漂移/进程缺 → nikki 服务排障；版本变更属独立决策（回顾研究报告 §1.3 版本注记） |
| 3 | tproxy 数据面：`docker exec immortalwrt nft list ruleset \| grep -i "tproxy to"` + 计数 | `tproxy to :7892` 规则存在且计数持续增长（基线：232 万包量级） | 规则缺失 → nikki 配置核查，超出本 plan 范围则另行立项 |
| 4 | 桌面侧现状：Mac `pm2 list` + `scutil --proxy` | pm2 空表 + 代理全 disabled（基线,Task 1 §2 / Task 5 §1.5；注意 en11 的 networksetup 服务名非 "Ethernet"——实为 "Thunderbolt Ethernet Slot 3" 且不被识别,故用 `scutil --proxy` 全代理状态口径） | 与 nixfiles 激活配置交叉判定（见 #5） |
| 5 | nixfiles 激活路径核对：Mac 当前使用的 homeConfig/darwin profile 是否含 `programs.clash.enable`（查 `flake.nix` 各 mkHome 的 `useProxy` 实参;仅 `ide-cn` 传 true） | **未启用（预期主流情形）**→ 属设计行为,「未运行」非故障 | 若启用但 pm2 空 → 走修复分支:`home-manager`/`darwin-rebuild` 重新激活并验证 `pm2 list` 出现 clash-meta;属 nixfiles PR(桌面模块),流程与容器 just 链无关 |
| 6 | （仅当 #5=启用）darwin buffer：`sysctl kern.ipc.maxsockbuf` | ≥7MB（8441037,quic-go 建议） | 低于则列 GATE-2 决策项（sysctl -w + LaunchDaemon 持久化,超本 plan 范围） |
| 7 | 一致性抽查(可选):`docker exec immortalwrt grep -cE '^[A-Za-z0-9_-]+:' /etc/nikki/profiles/config.yaml` | 顶层键计数 = 28,与 Task 2 §B 的 sops 源键 diff 结论一致(行数仅粗检,结构级核对以 sops 解密后的键 diff 为准) | 漂移 → 更新镜像（`just build` 即重新注入最新 sops 配置） |

**预期改动结论**：#1–#4、#7 全 PASS 为最可能结果（Task 2/5 实证容器侧一直健康）——**容器侧零动作**；#5 判定为「设计未启用」则桌面侧同样零动作,仅向用户口头确认桌面代理是否需要单独决策（列入 §4）。

### 2.4 A-c 实施核对流程（4×VPS，SSH 只读）

```bash
for h in 45.202.255.241 103.112.1.197 179.255.150.220 47.98.202.4; do
  ssh -i ~/.ssh/id_ed25519 root@$h -o BatchMode=yes '
    echo "== $HOSTNAME"; sysctl -n net.core.rmem_max net.core.wmem_max
    grep -iE "StreamReceiveWindow|ConnReceiveWindow|bandwidth|disablePathMTUDiscovery|congestion" /root/.config/hysteria/config.yaml || echo "quic-fields: none(expected)"
    ip -o link show | awk -F": " "{print \$2}"
  '
done
# c2（ssh 每台补）：ethtool -k $(ip route get 1.1.1.1 | grep -o "dev [^ ]*" | awk "{print \$2}") | grep tx-checksumming
```

判定路径：
- 全 PASS（rmem/wmem = 67108864，quic 字段 none，tx-checksumming on）→ **零改动**，记录核对结果即收尾；
- 任一偏离 → 输出差异清单；涉及改动时**本仓库不动**，另开 `personal-k3s-ops` 仓库独立 PR（role `vpn_server` 的 sysctl.yml / 配置模板，具体 diff 属该仓库 scope，本 plan 不含——plan Files-to-modify 预设）；
- c5 附带项（陈旧 hysteria 2.7.1 进程、frpc crash-loop）仅记录，处置授权见 §4 议题 12。

### 2.5 轨道 C 实施序（B 轨道完成后）

按 §1.3 顺序执行：C.1 物理迁移 → C.2 E1' 透传复测（含 NAS eth0 抬档前置，省略则洪泛命令出门前即 EMSGSIZE）→ C.3 P0–P4（每步节拍制）→ C.4 锚点判定 →（可选）C.5 9000 档。全部变更为运行时临时性（重启即回滚），P4 逆序回滚兜底贯穿全程；结果回落至研究报告基线 ±8/9% 噪声带为复稳判据。

---

## 3. 风险与回滚总表

| 项 | 变更内容 | 风险 | 中断/影响窗口 | 回滚 |
|---|---|---|---|---|
| A-a 容器切换 | 重建 immortalwrt 容器（新镜像） | Mac 默认网关 .2 中断（代理/公网路径）；内网 host route 直连不受影响 | ~30–90s（方案 A 短窗口）；若 just reset 且构建缓存失效可达数分钟 | `docker start` 旧容器不可行（已 rm）→ 全速恢复即 `just run`；镜像级异常回退：revert + `just build` |
| A-a fw4 mtu_fix 规则 | lan zone 生成 TCPMSS clamp | 规则形态不符预期 / clamp 值异常影响 bypass 直连 | 规则级，无中断 | 运行时 `uci set firewall.lan.mtu_fix=0 && uci commit firewall && fw4 restart`（即时）；git revert + rebuild（彻底） |
| A-a 与 C 交互 | C 轨道抬 br-lan 后 rt-mtu 基准变 2034 | 公网兜底失效（bypass TCP 大流黑洞） | 抬档期间 | C.3 P3 中复核；异常则切备选固定值 clamp（§2.2） |
| A-b | 无变更（纯核对） | 零 | 零 | N/A |
| A-c | 无变更（纯只读） | 零 | — | N/A |
| B 采购 | 物理换机 | 迁移期间全内网下行中断（换线时刻） | 分钟级（物理插拔） | 换回旧交换机、重插回原端口 |
| B 甄别实验（可选） | Mac MTU 临时 2034 | 混档窗口内超限 DF 丢包（ping 自身即探测）；既有 SSH/TCP 已证不中断（E1 §7.2），但**窗口内新建的大流量 TCP 会话将协商 MSS 1994、大段被旧交换机丢弃致挂起**——选低峰且避免 Mac/NAS 发起新的大文件传输 | ~10 分钟 | `sudo /sbin/ifconfig en11 mtu 1500`（临时性,重启即回滚） |
| C.2 E1' | NAS→Mac UDP 洪泛 2s×N 轮 | 瞬时 300Mbps 局部占用（新交换机上应正常到达） | 秒级 | 无需（自然结束） |
| C.3 P2 每步 | MTU 抬升五处 | br-lan 步有锁死管理面先例（GL.iNet 案,Task 3 R5）——备用通道为强制前置 | 实验窗口内 | 每步自带回滚命令（§1.3 表）；终极 `docker restart immortalwrt` |
| C.3 P4 终止条件 | — | 任何设备失联 >60s / mihomo crash / 吞吐劣化 >30% | — | 触发即全量逆序回滚 |

---

## 4. GATE-2 待决议题汇总（每项附建议默认值）

> 来源：研究报告 §8（五项 GATE-2 新议题 + 表格遗留核对项）+ task-5-exp-report §七 + switch-research 补充事实。

| # | 议题 | 建议默认值 | 说明 |
|---|---|---|---|
| 1 | **A 轨道执行授权**（本 plan §2.2/§2.3/§2.4） | **approve**：A-a 按方案落地，A-b/A-c 执行只读核对 | 全部为研究报告 §10 已预筛的低风险项；A-a 是唯一代码变更（一行 Dockerfile + 重建容器） |
| 2 | **哑交换机型号确认**（研究报告 §8 GATE-2-①） | 顺手提供（2 分钟）：物理标注/购买记录 | 非阻塞——行为学判定（1518B 硬阈值）已实锤；型号只丰富证据链（switch-research §2 品牌排除对照用） |
| 3 | **丢弃位归因最终甄别**（研究报告 §8 GATE-2-②；§1.2 协议） | **做**（下单前，10 分钟） | 可能省 ¥1499 或避免无效采购；不做也可接受（换机后 A1 P1.2 InJumbo 归因自动闭环,switch-research §9.5） |
| 4 | **换机采购决策**（研究报告 §8 GATE-2-④） | 绿联 CM996 ¥1499（京东自营）；预算敏感可候双 11/国补（switch-research §8-1） | 下单前可先做 #3；收货后立即按 §1.3 C.2 验证大帧透传 |
| 5 | **A2（GSO 负对照）补做与否**（研究报告 §8 GATE-2-③） | **暂缓** | 不影响任何落地决策（纯机理解释,H6 前半已过）；若日后 VPN 吞吐异常再启用,补做方案三选一中优先「镜像预烘焙」+ workload 源需另授权（task-5-exp-report §3.4） |
| 6 | **PVE 端口探测 / 9000 判据**（研究报告 §6.3 + switch-research §9 前提注） | **换机后做**：8972 payload DF 探测（E1 已留档 FAIL 判据） + PVE 上联 10G 协商复核 | PVE = Linux X520(switch-research 补充确认)；仅解锁 NAS↔PVE 单对 9000 档 |
| 7 | **A3 IPv6 尾巴**（研究报告 §8 GATE-2-⑤） | **不动** | 副本容器 RA 残留理论老化期（≤30min）已过;家庭设备 v6 出网长期异常再回查（task-5-exp-report §7-5） |
| 8 | **主路由 SKU 确认**（研究报告 §8-#2） | 顺手（2 分钟）：米家 App/铭牌 | 影响面已缩小到跨界（WAN/Wi-Fi）规格核对价值,非 jumbo 阻断项 |
| 9 | **M4 MTU 上限**（研究报告 §8-#3） | **B/C 轨道之间做**：M4 上 `networksetup -listvalidMTURange` | Mac↔M4 是 2034 档候选链路;同款 X520 推断同封顶 2034【推断】,实测 2 分钟闭环 |
| 10 | **UGOS Pro 版本**（研究报告 §8-#4） | **C.5 前读一次**（GUI 关于页） | ≥1.0.0.0888 才有 GUI 9000 入口;2034 档用 CLI 不受阻 |
| 11 | **桌面 mihomo 的去留**（A-b 核对产出后的决策） | 视 A-b #5 判定：设计未启用则维持现状,不另立修复 | 历史「pm2 常驻」描述与实测不符的根因要么是启用配置从未覆盖 Mac…要么确需修复——A-b 核对在 GATE-2 后 1 分钟内出结论,如需修复再议 |
| 12 | **vpn_premium 陈旧 hysteria 2.7.1 进程清理**(Task 5 §1.8-3) | **批准**（写操作,低风险——活跃 :20000 为 systemd 主进程 v2.13.0,老进程不持端口） | 执行方式独立于本 plan:经 personal-k3s-ops PR 或用户手动 `kill` |

---

## 附:本 plan 的证据锚点索引(供 6b 执行时回查)

- MSS clamp 缺陷:研究报告 §4.3、Task 2 §A4、Task 3 R5(fw4 语义与 lan zone 建议)
- 三项低成本清单原文:研究报告 §10 —— §10.1 容器 netns QUIC buffer(Task 2 §A3 已实测闭环 64MB → A-c c6 复核;VPS 侧为 Task 4 R7 服务端项 → A-c c1)/ §10.2 桌面 mihomo 常驻 → A-b / §10.3 fw4 mtu_fix → A-a
- 根因代码对照:`docker/immortalwrt/Dockerfile` L48-49(`uci delete network.wan` / `uci delete network.wan6` — 旁路由拓扑删 wan 接口 → wan zone 空置 → fw4 不生成 mssfix 规则)
- rebuild/切换链:`docker/immortalwrt/Justfile`(build/build-base/build-config/create-network/run/reset)
- E1 置底判定与 1518B 悬崖:研究报告 §7.1 / task-5-exp-report §2.4
- 甄别法协议:task-5-report §2.1 P1.2、task-5-exp-report §2.5-2、switch-research §9.5
- 轨道 C 完整协议原文:task-5-report §2.1(P0-P4 全命令)、终止条件与回归清单
- 收益预期:switch-research §9.2/§9.3/§9.5(指标-来源三列对照)
- VPN 零收益实证链:研究报告 §4.4(本 plan 全程不动 VPN 链路的依据)
