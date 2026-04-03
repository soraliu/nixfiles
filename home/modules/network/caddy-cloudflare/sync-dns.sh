#!/usr/bin/env bash
# 从 Caddyfile 解析域名，通过 Cloudflare API 同步 A 记录到本机公网 IP
# 用法: bash sync-dns.sh <caddy_config_dir>
# caddy_config_dir 下需要有 Caddyfile 和 cloudflare-token
set -euo pipefail

CADDY_DIR="${1:?用法: sync-dns.sh <caddy_config_dir>}"
CADDYFILE="${CADDY_DIR}/Caddyfile"
TOKEN_FILE="${CADDY_DIR}/cloudflare-token"

if [ ! -f "$CADDYFILE" ]; then
  echo "[sync-dns] Caddyfile 不存在: $CADDYFILE"
  exit 1
fi
if [ ! -f "$TOKEN_FILE" ]; then
  echo "[sync-dns] Cloudflare token 不存在: $TOKEN_FILE"
  exit 1
fi

CF_API_TOKEN=$(cat "$TOKEN_FILE")

# 获取本机公网 IP
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
  echo "[sync-dns] 无法获取公网 IP"
  exit 1
fi
echo "[sync-dns] 本机公网 IP: $PUBLIC_IP"

# 从 Caddyfile 解析域名（匹配 "xxx.soraliu.dev {" 模式）
DOMAINS=$(grep -oP '^[a-zA-Z0-9._-]+\.soraliu\.dev' "$CADDYFILE" | sort -u)
if [ -z "$DOMAINS" ]; then
  echo "[sync-dns] 未在 Caddyfile 中发现 *.soraliu.dev 域名"
  exit 0
fi

# 获取 Cloudflare Zone ID（soraliu.dev）
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=soraliu.dev" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | grep -oP '"id"\s*:\s*"\K[a-f0-9]+' | head -1)

if [ -z "$ZONE_ID" ]; then
  echo "[sync-dns] 无法获取 soraliu.dev 的 Zone ID"
  exit 1
fi
echo "[sync-dns] Zone ID: $ZONE_ID"

for DOMAIN in $DOMAINS; do
  echo "[sync-dns] 处理: $DOMAIN → $PUBLIC_IP"

  # 查询已有记录
  RECORD_JSON=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

  RECORD_ID=$(echo "$RECORD_JSON" | grep -oP '"id"\s*:\s*"\K[a-f0-9]+' | head -1)
  CURRENT_IP=$(echo "$RECORD_JSON" | grep -oP '"content"\s*:\s*"\K[0-9.]+' | head -1)

  if [ -n "$RECORD_ID" ]; then
    if [ "$CURRENT_IP" = "$PUBLIC_IP" ]; then
      echo "[sync-dns]   跳过: 记录已是 $PUBLIC_IP"
      continue
    fi
    # 更新已有记录
    curl -s -X PUT \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$PUBLIC_IP\",\"ttl\":300,\"proxied\":false}" > /dev/null
    echo "[sync-dns]   已更新: $CURRENT_IP → $PUBLIC_IP"
  else
    # 创建新记录
    curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$PUBLIC_IP\",\"ttl\":300,\"proxied\":false}" > /dev/null
    echo "[sync-dns]   已创建: $PUBLIC_IP"
  fi
done

echo "[sync-dns] 完成"
