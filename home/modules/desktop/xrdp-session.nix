# xrdp 会话卫生收敛: 会话级 DBus 隔离 + 断开会话自动回收, 治「新 RDP 会话黑屏秒退」。
# 只对 clawbot 的 Linux 桌面盒生效(经 desktop 模块的 !isDarwin gate), xrdp 未装则静默跳过。
#
# 根因(2026-10-22 复盘): xrdp 的 startwm.sh 直接 exec Xsession, 所有会话共享
# /run/user/0/bus(systemd user bus); 旧会话在共享 bus 上注册的 gpg-agent/ssh-agent/
# xfconfd 单例让新会话的 startxfce4 秒退, sesman 随即清理会话 → 客户端黑屏掉线;
# 而 sesman 默认 KillDisconnected=false, 异常断开的会话永久残留, 成为下次故障的污染源。
#
# 两处 /etc 收敛(dpkg conffile, apt 升级可能重置, 每次 switch 自愈):
#   1. startwm.sh: 两条 exec Xsession 行包进 dbus-run-session, 每个 RDP 会话独立
#      session bus, 旧会话单例不再可见(freedesktop 标准做法)
#   2. sesman.ini: KillDisconnected=true + DisconnectedTimeLimit=86400, 断开会话
#      24h 后自动回收(保留一天供人工重连找现场)
{ lib, system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  config = lib.mkIf (!isDarwin) {
    home.activation.convergeXrdpSession = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # shellcheck shell=bash
      [ -d /etc/xrdp ] || exit 0
      changed=0

      # 1) startwm.sh: Xsession 包进 dbus-run-session(幂等: 已 patched 则跳过)
      if [ -f /etc/xrdp/startwm.sh ] && ! grep -q 'dbus-run-session -- /etc/X11/Xsession' /etc/xrdp/startwm.sh; then
        sed -i \
          -e 's|^test -x /etc/X11/Xsession && exec /etc/X11/Xsession$|test -x /etc/X11/Xsession \&\& exec dbus-run-session -- /etc/X11/Xsession|' \
          -e 's|^exec /bin/sh /etc/X11/Xsession$|exec dbus-run-session -- /bin/sh /etc/X11/Xsession|' \
          /etc/xrdp/startwm.sh
        changed=1
      fi

      # 2) sesman.ini: 断开会话 24h 自动回收(幂等)
      if [ -f /etc/xrdp/sesman.ini ]; then
        if ! grep -q '^KillDisconnected=true$' /etc/xrdp/sesman.ini; then
          sed -i 's|^KillDisconnected=false$|KillDisconnected=true|' /etc/xrdp/sesman.ini
          changed=1
        fi
        if ! grep -q '^DisconnectedTimeLimit=86400$' /etc/xrdp/sesman.ini; then
          sed -i 's|^DisconnectedTimeLimit=0$|DisconnectedTimeLimit=86400|' /etc/xrdp/sesman.ini
          changed=1
        fi
      fi

      # 3) 只在真实变更时重启 xrdp 守护(重启不影响既有会话, 只短暂弹跳监听 socket)
      if [ "$changed" = 1 ]; then
        systemctl restart xrdp
      fi

      # 4) 兜底告警: 文件存在但收敛目标未达成(xrdp 升级改了格式), 提示但不阻塞 home switch
      if [ -f /etc/xrdp/startwm.sh ] && ! grep -q 'dbus-run-session -- /etc/X11/Xsession' /etc/xrdp/startwm.sh; then
        echo "warn: /etc/xrdp/startwm.sh does not converge; upstream xrdp may have changed its format" >&2
      fi
    '';
  };
}
