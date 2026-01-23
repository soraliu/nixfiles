#!/usr/bin/env bash

set -e

# ==============================================================================
# Configuration
# ==============================================================================
IMAGE_NAME="immortalwrt"
NETWORK_NAME="macnet"
IP_PREFIX="192.168.31"
NETMASK="255.255.255.0"
PARENT_INTERFACE="eth0"

GATEWAY="${IP_PREFIX}.1"
WRT_IP="${IP_PREFIX}.2"
MACVLAN_SHIM_IP="${IP_PREFIX}.250"
SUBNET="${IP_PREFIX}.0/24"

# ==============================================================================
# Helper Functions
# ==============================================================================
log_step() {
  local step="$1"
  local msg="$2"
  echo ""
  echo "========================================"
  echo "[Step ${step}] ${msg}"
  echo "========================================"
}

run_cmd() {
  local desc="$1"
  shift
  if "$@"; then
    echo "✓ ${desc}"
  else
    echo "✗ ${desc}"
    return 1
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Setup ImmortalWrt Docker container with macvlan network.

Options:
  -s, --step <N>    Execute only step N (1-4)
  -h, --help        Show this help message

Steps:
  1  Build the Docker image
  2  Create macvlan network
  3  Run the Docker container
  4  Configure macvlan-shim interface
EOF
  exit 0
}

# ==============================================================================
# Step Functions
# ==============================================================================
step_1_build_image() {
  log_step 1 "Build the ${IMAGE_NAME} docker image"
  docker build -t "${IMAGE_NAME}" \
    --platform linux/amd64 \
    --build-arg gateway="${GATEWAY}" \
    --build-arg netmask="${NETMASK}" \
    --build-arg wrt_ip="${WRT_IP}" \
    ./docker/images/"${IMAGE_NAME}"
}

step_2_create_network() {
  log_step 2 "Create macvlan network: ${NETWORK_NAME}"
  docker network create -d macvlan \
    --subnet="${SUBNET}" \
    --gateway="${GATEWAY}" \
    -o parent="${PARENT_INTERFACE}" \
    "${NETWORK_NAME}"
}

step_3_run_container() {
  log_step 3 "Run the ${IMAGE_NAME} docker container"
  docker run -d \
    --name="${IMAGE_NAME}" \
    --network="${NETWORK_NAME}" \
    --privileged \
    --restart=always \
    "${IMAGE_NAME}" \
    /sbin/init
}

step_4_configure_macvlan_shim() {
  log_step 4 "Configure macvlan-shim for traffic to ${WRT_IP}"

  run_cmd "Create macvlan-shim interface (bridge mode on ${PARENT_INTERFACE})" \
    ip link add macvlan-shim link "${PARENT_INTERFACE}" type macvlan mode bridge

  run_cmd "Assign IP ${MACVLAN_SHIM_IP}/32 to macvlan-shim" \
    ip addr add "${MACVLAN_SHIM_IP}/32" dev macvlan-shim

  run_cmd "Enable macvlan-shim interface" \
    ip link set macvlan-shim up

  run_cmd "Add route for ${WRT_IP}/32 via macvlan-shim" \
    ip route add "${WRT_IP}/32" dev macvlan-shim
}

# ==============================================================================
# Argument Parsing
# ==============================================================================
STEP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--step)
      STEP="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# ==============================================================================
# Main
# ==============================================================================
run_step() {
  case "$1" in
    1) step_1_build_image ;;
    2) step_2_create_network ;;
    3) step_3_run_container ;;
    4) step_4_configure_macvlan_shim ;;
    *) echo "Invalid step: $1 (valid: 1-4)"; exit 1 ;;
  esac
}

if [[ -n "${STEP}" ]]; then
  run_step "${STEP}"
else
  for s in 1 2 3 4; do
    run_step "$s"
  done
fi

echo ""
echo "Done."