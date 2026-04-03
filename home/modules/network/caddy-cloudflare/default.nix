{ pkgs, config, lib, ... }: {
  config = {
    programs = {
      sops = {
        decryptFiles = [{
          # 复用已有的 Cloudflare API Token，提取纯 token 值
          from = "secrets/.config/caddy/cloudflare-token.enc";
          to = ".config/caddy/cloudflare-token";
        }];
      };
    };

    # activation 阶段自动同步 Cloudflare DNS A 记录
    home.activation.syncCloudflareDns = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f ${config.home.homeDirectory}/.config/caddy/Caddyfile ] && \
         [ -f ${config.home.homeDirectory}/.config/caddy/cloudflare-token ]; then
        ${pkgs.bash}/bin/bash ${./sync-dns.sh} ${config.home.homeDirectory}/.config/caddy || true
      fi
    '';
  };
}
