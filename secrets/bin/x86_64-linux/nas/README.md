# 固件更新后恢复
sops -d secrets/bin/x86_64-linux/nas/init.enc.sh | ssh root@<NAS-内网地址> bash

# 或在 NAS 上直接执行（如果 overlay 未被清空）
ssh root@<NAS-内网地址> bash /volume1/.nas-scripts/init.sh

# FAQ

## macvlan-shim 是什么?

macvlan-shim 是为了解决 **NAS 与 Docker macvlan 容器之间的通信问题**。

### 问题背景

当 Docker 容器使用 macvlan 网络模式时：
- 容器拥有独立的 MAC 地址和 IP（旁路由容器即是一例）
- 容器可以直接与局域网其他设备通信
- **但 NAS 主机无法直接访问容器**，因为容器不在主机默认路由表中

### macvlan-shim 的作用

1. **创建虚拟接口**：在 NAS 上创建 `macvlan-shim` 接口（内网地址见运维记录）
2. **建立路由**：添加到旁路由容器的静态路由
3. **实现双向通信**：
   - NAS → 容器：通过 shim 接口和静态路由
   - 容器 → NAS：直接通过局域网

### 网络拓扑

```
[内网网段]
    │
    ├─ NAS
    │   └─ macvlan-shim ──→─┐
    │                                      │
    └─ ImmortalWrt 容器（旁路由） ←───┘  (静态路由)
```

### 实际用途

- **旁路由管理**：NAS 可以 SSH 到旁路由容器管理 ImmortalWrt
- **流量转发**：NAS 可以将特定流量通过旁路由转发
- **服务发现**：NAS 可以访问旁路由提供的 DNS、代理等服务

没有 macvlan-shim，NAS 就无法使用自己运行的旁路由容器。