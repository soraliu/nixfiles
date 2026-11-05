# 固件更新后恢复
sops -d secrets/bin/x86_64-linux/nas/init.enc.sh | ssh root@192.168.31.3 bash

# 或在 NAS 上直接执行（如果 overlay 未被清空）
ssh root@192.168.31.3 bash /volume1/.nas-scripts/init.sh

# FAQ

## 旁路由为什么用 redirect 而不是 tproxy?

本容器（macvlan + 容器 netns）里 **tproxy 的本地投递失效**：`lan_tproxy` 的 `tproxy to :7892`
计数在涨，但 mihomo 收不到任何连接，客户端 SYN 全部超时黑洞；表现为「`ip daddr @china_ip`
直连的中国流量正常、境外流量全挂、dashboard 看不到连接」。ICMP 与 DNS 劫持（走 nft redirect）
反而是正常的，因此改用 `nikki.proxy.tcp_mode=redirect`（DNAT 到 redir-port 7891）即可。

`ensure_bypass_ready` 会在每次初始化时校验并修正该项，同时补上：容器冷启动偶发缺失
`inet fw4` 规则集（缺失时连 NAT 都没有）时自动 reload firewall。

## 开机 203/EXEC 是什么?

`macvlan-shim.service` 的 `ExecStart` 指向 `/volume1/.nas-scripts/macvlan-shim.sh`，
而 `/volume1` 是独立挂载卷。unit 内 `RequiresMountsFor=/volume1` 缺失时，systemd 会在挂载完成前
启动服务并报 `Failed to locate executable ... : No such file or directory`（status=203/EXEC），
结果是 shim 接口与 `192.168.31.2` 的路由丢失（NAS 本机访问不到旁路由，LAN 客户端不受影响）。

## macvlan-shim 是什么?

macvlan-shim 是为了解决 **NAS 与 Docker macvlan 容器之间的通信问题**。

### 问题背景

当 Docker 容器使用 macvlan 网络模式时：
- 容器拥有独立的 MAC 地址和 IP（如 192.168.31.2）
- 容器可以直接与局域网其他设备通信
- **但 NAS 主机无法直接访问容器**，因为容器不在主机默认路由表中

### macvlan-shim 的作用

1. **创建虚拟接口**：在 NAS 上创建 `macvlan-shim` 接口（IP 192.168.31.250）
2. **建立路由**：添加到旁路由容器（192.168.31.2）的静态路由
3. **实现双向通信**：
   - NAS → 容器：通过 shim 接口和静态路由
   - 容器 → NAS：直接通过局域网

### 网络拓扑

```
[局域网 192.168.31.0/24]
    │
    ├─ NAS (192.168.31.3)
    │   └─ macvlan-shim (192.168.31.250) ──→─┐
    │                                      │
    └─ ImmortalWrt 容器 (192.168.31.2) ←───┘  (静态路由)
```

### 实际用途

- **旁路由管理**：NAS 可以 SSH 到 192.168.31.2 管理 ImmortalWrt
- **流量转发**：NAS 可以将特定流量通过旁路由转发
- **服务发现**：NAS 可以访问旁路由提供的 DNS、代理等服务

没有 macvlan-shim，NAS 就无法使用自己运行的旁路由容器。