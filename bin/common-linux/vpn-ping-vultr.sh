#!/bin/bash

nodes=(
    "lax-ca-us-ping.vultr.com"
    "sjo-ca-us-ping.vultr.com"
    "wa-us-ping.vultr.com"
    "tx-us-ping.vultr.com"
    "mex-mx-ping.vultr.com"
    "il-us-ping.vultr.com"
    "ga-us-ping.vultr.com"
    "tor-ca-ping.vultr.com"
    "fl-us-ping.vultr.com"
    "nj-us-ping.vultr.com"
    "hon-hi-us-ping.vultr.com"
    "man-uk-ping.vultr.com"
    "lon-gb-ping.vultr.com"
    "hnd-jp-ping.vultr.com"
    "sto-se-ping.vultr.com"
    "ams-nl-ping.vultr.com"
    "scl-cl-ping.vultr.com"
    "par-fr-ping.vultr.com"
    "osk-jp-ping.vultr.com"
    "fra-de-ping.vultr.com"
    "mad-es-ping.vultr.com"
    "waw-pl-ping.vultr.com"
    "sel-kor-ping.vultr.com"
    "sao-br-ping.vultr.com"
    "syd-au-ping.vultr.com"
    "tlv-il-ping.vultr.com"
    "mel-au-ping.vultr.com"
    "del-in-ping.vultr.com"
    "bom-in-ping.vultr.com"
    "sgp-ping.vultr.com"
    "blr-in-ping.vultr.com"
    "jnb-za-ping.vultr.com"
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
