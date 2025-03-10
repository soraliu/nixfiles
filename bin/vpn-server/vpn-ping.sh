#!/bin/bash

# vultr
# nodes=(
#     "lax-ca-us-ping.vultr.com"
#     "sjo-ca-us-ping.vultr.com"
#     "wa-us-ping.vultr.com"
#     "tx-us-ping.vultr.com"
#     "mex-mx-ping.vultr.com"
#     "il-us-ping.vultr.com"
#     "ga-us-ping.vultr.com"
#     "tor-ca-ping.vultr.com"
#     "fl-us-ping.vultr.com"
#     "nj-us-ping.vultr.com"
#     "hon-hi-us-ping.vultr.com"
#     "man-uk-ping.vultr.com"
#     "lon-gb-ping.vultr.com"
#     "hnd-jp-ping.vultr.com"
#     "sto-se-ping.vultr.com"
#     "ams-nl-ping.vultr.com"
#     "scl-cl-ping.vultr.com"
#     "par-fr-ping.vultr.com"
#     "osk-jp-ping.vultr.com"
#     "fra-de-ping.vultr.com"
#     "mad-es-ping.vultr.com"
#     "waw-pl-ping.vultr.com"
#     "sel-kor-ping.vultr.com"
#     "sao-br-ping.vultr.com"
#     "syd-au-ping.vultr.com"
#     "tlv-il-ping.vultr.com"
#     "mel-au-ping.vultr.com"
#     "del-in-ping.vultr.com"
#     "bom-in-ping.vultr.com"
#     "sgp-ping.vultr.com"
#     "blr-in-ping.vultr.com"
#     "jnb-za-ping.vultr.com"
# )

# lightnode
# nodes=(
#   "38.54.94.46"
#   "38.54.110.230"
#   "38.54.84.221"
#   "38.54.105.45"
#   "38.54.38.251"
#   "38.54.8.86"
#   "38.54.117.239"
#   "223.19.209.2"
#   "38.54.4.29"
#   "38.54.15.200"
#   "38.54.85.82"
#   "38.54.107.70"
#   "38.54.40.36"
#   "38.54.63.87"
#   "38.54.17.203"
#   "38.54.37.103"
#   "38.54.42.91"
#   "38.54.57.229"
#   "38.54.61.49"
#   "38.54.50.202"
#   "38.54.59.114"
#   "38.54.2.132"
#   "38.54.27.57"
#   "38.54.29.51"
#   "38.54.96.183"
#   "125.59.104.123"
#   "38.54.116.239"
#   "38.54.124.111"
#   "38.54.122.55"
#   "38.54.79.90"
#   "38.54.71.57"
#   "38.60.223.158"
#   "38.54.45.86"
#   "38.60.191.234"
#   "38.60.224.195"
#   "38.54.20.86"
#   "154.93.51.14"
#   "154.93.37.171"
#   "154.223.16.107"
#   "156.244.41.15"
#   "156.244.39.140"
# )

# lightnode v2
nodes=(
  '38.54.94.46'
  '38.54.110.230'
  '38.54.84.221'
  '38.54.105.45'
  '38.54.38.251'
  '38.54.8.86'
  '38.54.117.239'
  '38.54.31.125'
  '38.54.4.29'
  '38.54.15.200'
  '38.54.85.82'
  '38.54.107.70'
  '38.54.40.36'
  '38.54.63.87'
  '38.54.17.203'
  '38.54.37.103'
  '38.54.42.91'
  '38.54.57.229'
  '38.54.61.49'
  '38.54.50.202'
  '38.54.59.114'
  '38.54.2.132'
  '38.54.27.57'
  '38.54.29.51'
  '38.54.96.183'
  '38.54.68.72'
  '38.54.116.239'
  '38.54.124.111'
  '183.228.3.204'
  '38.54.79.90'
  '38.54.71.57'
  '38.60.223.158'
  '38.54.45.86'
  '38.60.191.234'
  '38.60.224.195'
  '38.54.20.86'
  '154.93.51.14'
  '154.93.37.171'
  '154.223.16.107'
  '156.244.41.15'
  '156.244.39.140'
)

tmpfile=$(mktemp)

ping_node() {
    node=$1
    avg_ping=$(ping -c 4 "$node" | tail -1 | awk '{print $4}' | cut -d '/' -f 2)

    if [[ -n "$avg_ping" ]]; then
        echo "$node avg ping: $avg_ping ms"
        echo "$avg_ping $node" >> "$tmpfile"
    else
        echo "Can't ping: $node"
    fi
}

for node in "${nodes[@]}"; do
    ping_node "$node"
done

echo "Top 3 nodes:"
sort -n "$tmpfile" | head -n 3

rm "$tmpfile"
