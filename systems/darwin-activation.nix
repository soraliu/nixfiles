{ homeUser, lib, ... }:
let
  userHome = "/Users/${homeUser}";
in
{
  # 需要 root 权限的 activation scripts，在 home-manager 激活后执行
  # 使用 mkAfter 确保 postActivation.text 追加到 home-manager 注入的内容之后
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # PM2 startup：生成 LaunchAgent plist，实现开机自启
    PM2_BIN="${userHome}/.volta/bin/pm2"
    if [ -x "$PM2_BIN" ]; then
      echo "configuring PM2 startup for ${homeUser}..."
      sudo -u ${homeUser} --set-home "$PM2_BIN" startup || true
    else
      echo "PM2 not found at $PM2_BIN, skipping startup configuration"
    fi

    # Caddy 根证书信任：将 Caddy 本地 CA 添加到系统 keychain（已信任则跳过）
    ROOT_CERT="${userHome}/Library/Application Support/Caddy/pki/authorities/local/root.crt"
    if [ -f "$ROOT_CERT" ]; then
      if /usr/bin/security find-certificate -c "Caddy Local Authority" /Library/Keychains/System.keychain &>/dev/null; then
        echo "Caddy root certificate already trusted, skipping"
      else
        echo "trusting Caddy root certificate..."
        /usr/bin/security add-trusted-cert -d -r trustRoot \
          -k /Library/Keychains/System.keychain "$ROOT_CERT" || true
      fi
    else
      echo "Caddy root certificate not found, skipping trust"
    fi
  '';
}
