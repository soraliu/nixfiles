#!/usr/bin/env bash
# Task 5 B2/B3/B6 补充轮 — 1Gb 源拉满时间窗：每路径 2×55s + VPS 抓包 + 30s 中窗
set -u
cd /Users/soraliu/.pi/worktree/nixfiles/research-jumbo-mtu/.superpowers/sdd/jumbo-mtu-research || exit 1
URL="https://proof.ovh.net/files/1Gb.dat"

nas_frame() {
  echo "TS $(date +%s.%N)"
  echo "CPU $(head -1 /proc/stat)"
  echo "DEV $(grep -w eth0 /proc/net/dev)"
  echo "MIHOMO $(awk -v p=$(pgrep -fx '/usr/bin/mihomo -d /etc/nikki/run') '{if($1==p) print $14, $15}' /proc/$p/stat 2>/dev/null || echo NA)"
}
VPNS=data/task-5-nas-vpn-snapshots.txt
MEN=data/task-5-mac-netstat-en11-vpn.txt
echo "==== 补充轮（1Gb/55s，$(date '+%T')） ====" >> $VPNS
echo "==== 补充轮（1Gb/55s） ====" >> $MEN

curl_run() { # $1=tag $2=proxyarg
  echo "[$1 start $(date '+%T')]"
  ssh -o BatchMode=yes root@192.168.31.3 "$(declare -f nas_frame); nas_frame" >> $VPNS 2>/dev/null
  curl -s -m 55 $2 -o /dev/null -w "$1,%{time_namelookup},%{time_connect},%{time_appconnect},%{time_starttransfer},%{time_total},%{size_download},%{speed_download}\n" "$URL" >> data/task-5-vpn-curl.txt
  ssh -o BatchMode=yes root@192.168.31.3 "$(declare -f nas_frame); nas_frame; echo" >> $VPNS 2>/dev/null
}

# ---- 路径 a r4：30s 中窗 ----
( sleep 12; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN; sleep 30; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN ) &
curl_run gw-r4 ""
wait

# ---- 路径 a r5 + VPS 抓包（满载期间 500 包） ----
ssh -o BatchMode=yes -i ~/.ssh/id_ed25519 root@103.112.1.197 'timeout 65 tcpdump -i ens3 -c 500 -w /tmp/task5-quic-download.pcap "udp portrange 20000-30000"' 2>/dev/null &
VPSCAP=$!
sleep 3
curl_run gw-r5 ""
wait $VPSCAP 2>/dev/null; echo "(vps capture rc=$?)"

# ---- 路径 b r4：30s 中窗 ----
( sleep 12; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN; sleep 30; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN ) &
curl_run proxy-r4 "-x http://192.168.31.2:7890"
wait
echo "==== DONE $(date '+%T') ===="
