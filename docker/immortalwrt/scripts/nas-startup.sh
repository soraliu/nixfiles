#!/usr/bin/env bash

# ==============================================================================
# NAS Startup Script - Network Persistence for ImmortalWrt
# ==============================================================================
# This script configures the macvlan-shim interface to enable communication
# between the NAS host and the ImmortalWrt container.
# Should be run at NAS startup (e.g., via Task Scheduler).
# ==============================================================================

set -e

# ==============================================================================
# Configuration
# ==============================================================================
IP_PREFIX="192.168.31"
PARENT_INTERFACE="eth0"
MACVLAN_SHIM_IF="macvlan-shim"
MACVLAN_SHIM_IP="${IP_PREFIX}.250"
WRT_IP="${IP_PREFIX}.2"

# ==============================================================================
# Helper Functions
# ==============================================================================
log_info() {
  echo "[INFO] $1"
}

log_success() {
  echo "[OK]   $1"
}

log_error() {
  echo "[ERR]  $1"
}

# ==============================================================================
# Main Logic
# ==============================================================================
echo "Starting NAS Network Persistence Script..."

# Wait for network services to fully start
sleep 10

# 1. Enable promiscuous mode on physical interface
ip link set dev "${PARENT_INTERFACE}" promisc on
log_success "Promiscuous mode enabled on ${PARENT_INTERFACE}"

# 2. Create macvlan-shim interface if not exists
if ! ip link show "${MACVLAN_SHIM_IF}" > /dev/null 2>&1; then
  ip link add link "${PARENT_INTERFACE}" name "${MACVLAN_SHIM_IF}" type macvlan mode bridge
  log_success "Interface ${MACVLAN_SHIM_IF} created"
else
  log_info "Interface ${MACVLAN_SHIM_IF} already exists"
fi

# 3. Configure IP and bring up the interface
# Use /32 netmask to avoid routing table conflicts
ip addr flush dev "${MACVLAN_SHIM_IF}"
ip addr add "${MACVLAN_SHIM_IP}/32" dev "${MACVLAN_SHIM_IF}"
ip link set "${MACVLAN_SHIM_IF}" up
log_success "IP ${MACVLAN_SHIM_IP} assigned to ${MACVLAN_SHIM_IF}"

# 4. Add static route to ImmortalWrt container
# Force NAS to use the shim interface when accessing the container IP
if ! ip route show "${WRT_IP}/32" | grep -q "${MACVLAN_SHIM_IF}"; then
  ip route add "${WRT_IP}/32" dev "${MACVLAN_SHIM_IF}"
  log_success "Route to ${WRT_IP} added via ${MACVLAN_SHIM_IF}"
else
  log_info "Route to ${WRT_IP} already exists"
fi

echo "Done."
