#!/usr/bin/env bash
# Task 5 B2/B3/B6 — VPN 双路径基线 + VPS 侧 QUIC 抓包（修正轮 v2：OVH 100Mb 源）
set -u
cd /Users/soraliu/.pi/worktree/nixfiles/research-jumbo-mtu/.superpowers/sdd/jumbo-mtu-research || exit 1
URL="https://proof.ovh.net/files/100Mb.dat"

nas_frame() {
  echo "TS $(date +%s.%N)"
  echo "CPU $(head -1 /proc/stat)"
  echo "DEV $(grep -w eth0 /proc/net/dev)"
  echo "MIHOMO $(awk -v p=$(pgrep -fx '/usr/bin/mihomo -d /etc/nikki/run') '{if($1==p) print $14, $15}' /proc/$p/stat 2>/dev/null || echo NA)"
}
VPNS=data/task-5-nas-vpn-snapshots.txt
MEN=data/task-5-mac-netstat-en11-vpn.txt
echo "==== NAS VPN 阶段采样（OVH 100Mb / 60s 上限） ====" > $VPNS
echo "==== Mac en11 netstat（VPN 阶段，30s 中窗） ====" > $MEN
echo "tag,namelookup,connect,appconnect,starttransfer,total,bytes,speed_Bps" > data/task-5-vpn-curl.txt

curl_run() { # $1=tag $2=proxyarg
  echo "[$1 start $(date '+%T')]"
  ssh -o BatchMode=yes root@192.168.31.3 "$(declare -f nas_frame); nas_frame" >> $VPNS 2>/dev/null
  curl -s -m 60 $2 -o /dev/null -w "$1,%{time_namelookup},%{time_connect},%{time_appconnect},%{time_starttransfer},%{time_total},%{size_download},%{speed_download}\n" "$URL" >> data/task-5-vpn-curl.txt
  ssh -o BatchMode=yes root@192.168.31.3 "$(declare -f nas_frame); nas_frame; echo" >> $VPNS 2>/dev/null
}

# ---- 路径 a r1（含 30s 中窗 en11 计数） ----
( sleep 15; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN; sleep 30; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN ) &
curl_run gw-r1 ""
wait

# ---- 路径 a r2 + VPS 抓包（bulk 下载期间，500 包） ----
ssh -o BatchMode=yes -i ~/.ssh/id_ed25519 root@103.112.1.197 'timeout 70 tcpdump -i ens3 -c 500 -w /tmp/task5-quic-download.pcap "udp portrange 20000-30000"' 2>/dev/null &
VPSCAP=$!
sleep 3   # 让 tcpdump 先就位
curl_run gw-r2 ""
wait $VPSCAP 2>/dev/null; echo "(vps capture rc=$?)"

# ---- 路径 a r3 ----
curl_run gw-r3 ""

# ---- 路径 b：显式代理 ----
curl_run proxy-r1 "-x http://192.168.31.2:7890"
( sleep 15; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN; sleep 30; { echo "TS $(date +%s.%N)"; netstat -I en11 | grep -w en11 | head -1; } >> $MEN ) &
curl_run proxy-r2 "-x http://192.168.31.2:7890"
wait
curl_run proxy-r3 "-x http://192.168.31.2:7890"
echo "==== DONE $(date '+%T') ===="
