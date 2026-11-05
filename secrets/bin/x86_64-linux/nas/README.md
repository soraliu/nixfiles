# 固件更新后恢复

`NAS_SSH_TARGET` 按本地私有连接记录设置，具体地址不写入仓库。

```bash
sops -d secrets/bin/x86_64-linux/nas/init.enc.sh | ssh "$NAS_SSH_TARGET" bash

# 如果持久卷上的脚本仍在，也可直接执行
ssh "$NAS_SSH_TARGET" bash /volume1/.nas-scripts/init.sh
```

管道执行不会更新持久卷上的 `init.sh`；需要更新脚本时，单独复制解密后的文件并保持权限为 `700`。

## TPROXY 规则命中，为什么仍然无法代理？

容器可能从 NAS 继承 `net.ipv4.conf.all.src_valid_mark=1`。来源地址校验会携带
TPROXY 标记查询路由，误命中本地投递路由并丢包，表现为规则计数上涨、Mihomo 收不到连接。
TCP 改用 REDIRECT 只绕过 TCP 的故障路径，UDP 仍然失败。

在旁路由容器内设置 `net.ipv4.conf.all.src_valid_mark=0`，保留 TCP/UDP TPROXY。
新容器通过 Docker 的 `--sysctl` 参数固定该值；`ensure_bypass_ready` 会为已有容器应用该参数、
写入 `/etc/sysctl.conf` 并校验代理模式。NAS 主机的参数保持原值。

[Linux 参数说明](https://docs.kernel.org/networking/ip-sysctl.html)：透明代理只在一个方向使用标记时，
来源校验应排除该标记。可在隔离网络命名空间中保持规则和报文不变，对照参数为 `1` 与 `0` 时的 UDP 接收结果。

恢复后应验证真实 TCP HTTPS 请求和 UDP 请求，并确认 Mihomo 入口类型为 `TProxy`。
DNS 劫持成功或规则计数上涨，单独都不足以证明 UDP 代理正常。

`ensure_bypass_ready` 还会等待 Mihomo 就绪，在容器冷启动缺少 `inet fw4` 规则集时重新加载防火墙。

## 开机 203/EXEC 是什么？

`macvlan-shim.service` 的脚本位于独立持久卷。unit 使用 `RequiresMountsFor=/volume1`
等待挂载完成，避免脚本尚不可见时启动并报 `203/EXEC`。

## macvlan-shim 是什么？

Docker macvlan 默认隔离宿主机与其容器的直接通信。NAS 上的 shim 接口与指向旁路由的静态路由，
让 NAS 能访问旁路由的管理、DNS 和代理服务。局域网其他设备与旁路由之间的通信不依赖这个 shim。
