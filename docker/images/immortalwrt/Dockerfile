FROM immortalwrt/rootfs:x86-64-openwrt-24.10.4

# 设置环境变量，防止安装过程中出现交互式提示
ENV CI=1

ARG gateway="192.168.31.1"
ARG netmask="255.255.255.0"
ARG wrt_ip="192.168.31.2"

# ----------------------------------------------------
# 1. 基础环境更新与工具安装
# ----------------------------------------------------
# 更新 opkg 列表并安装 HTTPS 支持所需的包 (wget-ssl, ca-bundle) [4]
RUN mkdir -p /var/lock && opkg update && \
    opkg install wget-ssl ca-bundle curl

# ----------------------------------------------------
# 2. 安装 Nikki (Clash 客户端)
# ----------------------------------------------------
# 添加 Nikki 的软件源 Feed [5]
RUN wget -O - https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash

# 更新 Feed 并安装 Nikki 及其依赖
RUN opkg update && \
    opkg install nikki luci-app-nikki luci-i18n-nikki-zh-cn

# ----------------------------------------------------
# 3. 固化旁路由网络配置 (UCI 设置)
# ----------------------------------------------------
# 设定 LAN 口为静态 IP，指向主路由网关 [2, 6]
# 请根据实际情况修改 ipaddr (旁路由IP) 和 gateway (主路由IP)
RUN uci get network.lan >/dev/null 2>&1 || uci set network.lan=interface
RUN uci set network.lan.proto='static' && \
    uci set network.lan.ipaddr="$wrt_ip" && \
    uci set network.lan.netmask="$netmask" && \
    uci set network.lan.gateway="$gateway" && \
    uci set network.lan.dns="$gateway 223.5.5.5" && \
    uci delete network.wan 2>/dev/null && \
    uci delete network.wan6 2>/dev/null && \
    uci commit network

# 禁用 LAN 口的 DHCP 服务，避免与主路由冲突 [2, 7]
RUN uci set dhcp.lan.ignore='1' && \
    uci commit dhcp

# ----------------------------------------------------
# 4. 固化防火墙配置 (关键步骤)
# ----------------------------------------------------
# 开启 IP 动态伪装 (Masquerading)，确保旁路由流量能正常 NAT 转发 [8, 9]
RUN uci set firewall.lan=zone && \
    uci set firewall.lan.name='lan' && \
    uci set firewall.lan.network='lan' && \
    uci set firewall.lan.input='ACCEPT' && \
    uci set firewall.lan.output='ACCEPT' && \
    uci set firewall.lan.forward='ACCEPT' && \
    uci set firewall.lan.masq='1' && \
    uci commit firewall

# 清理
RUN rm -rf /var/opkg-lists/* && \
    rm -rf /var/lock

# ----------------------------------------------------
# 5. 启动设置
# ----------------------------------------------------
# 容器启动命令，使用 /sbin/init 初始化系统进程
CMD ["/sbin/init"]