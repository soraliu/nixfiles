#!/usr/bin/env bash
# Task 5 B2 补测 — mihomo 进程 CPU 采样修复轮（直引号内联，同 LAN 阶段验证过的样式）
set -u
cd /Users/soraliu/.pi/worktree/nixfiles/research-jumbo-mtu/.superpowers/sdd/jumbo-mtu-research || exit 1
URL="https://proof.ovh.net/files/1Gb.dat"
VPNS=data/task-5-nas-vpn-snapshots.txt
MEN=data/task-5-mac-netstat-en11-vpn.txt
echo "==== 补测轮（mihomo 直采样，$(date '+%T')） ====" >> $VPNS
echo "==== 补测轮（mihomo 直采样） ====" >> $MEN

nas_snap() {
  ssh -o BatchMode=yes root@192.168.31.3 '
  MP=$(pgrep -fx "/usr/bin/mihomo -d /etc/nikki/run")
  echo "TS $(date +%s.%N)"
  echo "MIHOMO $(awk -v p=$MP "{if(\$1==p) print \$14, \$15}" /proc/$MP/stat 2>/dev/null || echo NA)"
  echo "CPU $(head -1 /proc/stat)"
  echo "DEV $(grep -w eth0 /proc/net/dev)"
  ' 2>/dev/null
}

run_round() { # $1=tag $2=proxyarg
  echo "[$1 start $(date '+%T')]"
  nas_snap >> $VPNS
  curl -s -m 55 $2 -o /dev/null -w "$1,%{time_namelookup},%{time_connect},%{time_appconnect},%{time_starttransfer},%{time_total},%{size_download},%{speed_download}\n" "$URL" >> data/task-5-vpn-curl.txt
  nas_snap >> $VPNS
  echo "" >> $VPNS
}

# gw-r6 含 30s 中窗
( sleep 12; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN; sleep 30; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN ) &
run_round gw-r6 ""
wait
run_round gw-r7 ""
# proxy-r5 含 30s 中窗
( sleep 12; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN; sleep 30; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN ) &
run_round proxy-r5 "-x http://192.168.31.2:7890"
wait
run_round proxy-r6 "-x http://192.168.31.2:7890"
echo "==== DONE $(date '+%T') ===="
