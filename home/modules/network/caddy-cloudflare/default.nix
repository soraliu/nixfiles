{ pkgs, config, lib, ... }: let
  caddyDir = "${config.home.homeDirectory}/.config/caddy";
  curl = "${pkgs.curl}/bin/curl";
  grep = "${pkgs.gnugrep}/bin/grep";
  head = "${pkgs.coreutils}/bin/head";
  sort = "${pkgs.coreutils}/bin/sort";
  cat = "${pkgs.coreutils}/bin/cat";
  # 所有外部命令使用 nix store 完整路径，确保在纯净 PATH 环境下可用
  syncDnsScript = pkgs.writeShellScript "sync-dns.sh" ''
    set -euo pipefail

    CADDY_DIR="''${1:?用法: sync-dns.sh <caddy_config_dir>}"
    CADDYFILE="''${CADDY_DIR}/Caddyfile"
    TOKEN_FILE="''${CADDY_DIR}/cloudflare-token"

    if [ ! -f "$CADDYFILE" ]; then
      echo "[sync-dns] Caddyfile 不存在: $CADDYFILE"
      exit 1
    fi
    if [ ! -f "$TOKEN_FILE" ]; then
      echo "[sync-dns] Cloudflare token 不存在: $TOKEN_FILE"
      exit 1
    fi

    CF_API_TOKEN=$(${cat} "$TOKEN_FILE")

    PUBLIC_IP=$(${curl} -s https://api.ipify.org || ${curl} -s https://ifconfig.me)
    if [ -z "$PUBLIC_IP" ]; then
      echo "[sync-dns] 无法获取公网 IP"
      exit 1
    fi
    echo "[sync-dns] 本机公网 IP: $PUBLIC_IP"

    DOMAINS=$(${grep} -oP '^[a-zA-Z0-9._-]+\.soraliu\.dev' "$CADDYFILE" | ${sort} -u)
    if [ -z "$DOMAINS" ]; then
      echo "[sync-dns] 未在 Caddyfile 中发现 *.soraliu.dev 域名"
      exit 0
    fi

    ZONE_ID=$(${curl} -s -X GET "https://api.cloudflare.com/client/v4/zones?name=soraliu.dev" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" | ${grep} -oP '"id"\s*:\s*"\K[a-f0-9]+' | ${head} -1)

    if [ -z "$ZONE_ID" ]; then
      echo "[sync-dns] 无法获取 soraliu.dev 的 Zone ID"
      exit 1
    fi
    echo "[sync-dns] Zone ID: $ZONE_ID"

    for DOMAIN in $DOMAINS; do
      echo "[sync-dns] 处理: $DOMAIN → $PUBLIC_IP"

      RECORD_JSON=$(${curl} -s -X GET \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

      RECORD_ID=$(echo "$RECORD_JSON" | ${grep} -oP '"id"\s*:\s*"\K[a-f0-9]+' | ${head} -1 || true)
      CURRENT_IP=$(echo "$RECORD_JSON" | ${grep} -oP '"content"\s*:\s*"\K[0-9.]+' | ${head} -1 || true)

      if [ -n "$RECORD_ID" ]; then
        if [ "$CURRENT_IP" = "$PUBLIC_IP" ]; then
          echo "[sync-dns]   跳过: 记录已是 $PUBLIC_IP"
          continue
        fi
        ${curl} -s -X PUT \
          "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$PUBLIC_IP\",\"ttl\":300,\"proxied\":false}"
        echo "[sync-dns]   已更新: $CURRENT_IP → $PUBLIC_IP"
      else
        ${curl} -s -X POST \
          "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
          -H "Authorization: Bearer $CF_API_TOKEN" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$PUBLIC_IP\",\"ttl\":300,\"proxied\":false}"
        echo "[sync-dns]   已创建: $PUBLIC_IP"
      fi
    done

    echo "[sync-dns] 完成"
  '';
in {
  config = {
    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/caddy/cloudflare-token.enc";
          to = ".config/caddy/cloudflare-token";
        }];
      };
    };

    # activation 阶段自动同步 Cloudflare DNS A 记录
    home.activation.syncCloudflareDns = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f ${caddyDir}/Caddyfile ] && \
         [ -f ${caddyDir}/cloudflare-token ]; then
        ${syncDnsScript} ${caddyDir} || true
      fi
    '';
  };
}
