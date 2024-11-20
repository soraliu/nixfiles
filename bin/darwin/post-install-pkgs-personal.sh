#!/usr/bin/env bash

source ./install-dmg.util.sh

install_dmg -n 'Wechat.app' -u 'https://dldir1.qq.com/weixin/mac/WeChatMac.dmg' &
install_dmg -n 'WhatsApp.app' -u 'https://web.whatsapp.com/desktop/mac_native/release/?configuration=Release' &

if $(uname -m | grep -q 'arm'); then
  install_dmg -n 'BaiduNetdisk_mac.app' -u 'https://pkg-ant.baidu.com/issue/netdisk/MACguanjia/4.36.2/BaiduNetdisk_mac_4.36.2_x64.dmg' &
elif $(uname -m | grep -q 'x86'); then
  install_dmg -n 'BaiduNetdisk_mac.app' -u 'https://pkg-ant.baidu.com/issue/netdisk/MACguanjia/4.36.2/BaiduNetdisk_mac_4.36.2_arm64.dmg' &
else
  echo "Error: Unknown arch $(uname -m)"
fi

wait
