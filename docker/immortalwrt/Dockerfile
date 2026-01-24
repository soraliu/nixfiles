FROM immortalwrt/rootfs:x86-64-openwrt-24.10.4

# ============================================================
# Build Arguments & Environment
# ============================================================
ENV CI=1

ARG gateway="192.168.31.1"
ARG netmask="255.255.255.0"
ARG wrt_ip="192.168.31.2"

# ============================================================
# 1. Initialize Package Manager & Install Base Tools
# ============================================================
# Add Nikki package feed
RUN wget -O - https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash
# Setup mirror switching script for package manager resilience
RUN mkdir -p /var/lock && \
    printf '#!/bin/sh\nMIRRORS="downloads.immortalwrt.org mirrors.ustc.edu.cn/immortalwrt mirrors.geekpie.club/immortalwrt"\nfor m in $MIRRORS; do\n    if wget -q --spider https://$m/releases/ 2>/dev/null; then\n        echo "Mirror available: https://$m"\n        sed -i "s|downloads.immortalwrt.org|$m|g" /etc/opkg/distfeeds.conf\n        opkg update\n        exit 0\n    fi\ndone\necho "No available mirror found"\nexit 1\n' > /usr/bin/opkg-mirror-switch && \
    chmod +x /usr/bin/opkg-mirror-switch && \
    /usr/bin/opkg-mirror-switch

# Install base utilities
RUN opkg install wget-ssl ca-bundle curl openssh-sftp-server

# Install and configure UI theme
RUN opkg install luci-theme-argon && \
    uci set luci.main.lang='zh_cn'

# ============================================================
# 2. Configure Network (LAN Bridge & Static IP)
# ============================================================
# Setup bridge device for LAN interface
RUN uci add network device && \
    uci set network.@device[-1].name='br-lan' && \
    uci set network.@device[-1].type='bridge' && \
    uci add_list network.@device[-1].ports='eth0'

# Configure LAN interface with static IP pointing to main router gateway
# Note: Adjust ipaddr (subsidiary router IP) and gateway (main router IP) as needed
RUN uci get network.lan >/dev/null 2>&1 || uci set network.lan=interface

RUN uci set network.lan.proto='static' && \
    uci set network.lan.device='br-lan' && \
    uci set network.lan.ipaddr="$wrt_ip" && \
    uci set network.lan.netmask="$netmask" && \
    uci set network.lan.gateway="$gateway" && \
    uci set network.lan.dns="$gateway 223.5.5.5" && \
    uci delete network.wan 2>/dev/null && \
    uci delete network.wan6 2>/dev/null

# Disable DHCP on LAN to avoid conflicts with main router
RUN uci set dhcp.lan.ignore='1'

# ============================================================
# 3. Configure Firewall (NAT & Traffic Rules)
# ============================================================
# Enable IP masquerading for proper NAT forwarding of subsidiary router traffic
RUN LAN_ID=$(uci show firewall | grep "\.name='lan'" | awk -F. '{print $2}' | head -n 1) && \
    [ -n "$LAN_ID" ] && uci rename firewall."$LAN_ID"='lan'; \
    uci set firewall.lan.input='ACCEPT' && \
    uci set firewall.lan.output='ACCEPT' && \
    uci set firewall.lan.forward='ACCEPT' && \
    uci set firewall.lan.masq='1'

# ============================================================
# 4. Install & Configure Nikki (Clash Client)
# ============================================================
# Install Nikki and related packages
RUN opkg install nikki luci-app-nikki luci-i18n-nikki-zh-cn
# Configure Nikki proxy mode and access control
RUN uci set nikki.proxy.tcp_mode='tproxy' && \
    uci set nikki.proxy.udp_mode='tproxy' && \
    uci set nikki.mixin.ipv6='0' && \
    uci set nikki.mixin.dns_ipv6='0' && \
    uci set nikki.@authentication[0].enabled='0' && \
    uci set nikki.mixin.tun_enabled='0' && \
    uci set nikki.config.enabled='1' && \
    uci set nikki.config.profile='file:config.yaml' && \
    uci add_list nikki.@router_access_control[0].user="root"

# ============================================================
# 5. Finalize Configuration & Cleanup
# ============================================================
# Commit all UCI configuration changes
RUN uci commit

# Clean up package manager cache
RUN rm -rf /var/opkg-lists/* /var/lock

# ============================================================
# 6. Container Startup
# ============================================================
CMD ["/sbin/init"]