{ pkgs, config, ... }: let
  caddyDir = "${config.home.homeDirectory}/.config/caddy";
  # 启动脚本：拼接 local_certs 全局选项 + 共享 Caddyfile，使用自签证书
  script = pkgs.writeText "caddy-local-start.sh" ''
    #!/bin/sh
    printf '{\n    local_certs\n}\n\n' > ${caddyDir}/Caddyfile.local
    cat ${caddyDir}/Caddyfile >> ${caddyDir}/Caddyfile.local
    exec ${pkgs.caddy}/bin/caddy run --config ${caddyDir}/Caddyfile.local
  '';
in {
  config = {
    home = {
      packages = with pkgs; [
        caddy
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/caddy/Caddyfile.enc";
          to = ".config/caddy/Caddyfile";
        }];
      };
      pm2 = {
        services = [{
          name = "caddy";
          script = script;
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
