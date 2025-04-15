{ pkgs, lib, config, ... }: let
  script = pkgs.writeText "nginx-start-script.sh" ''
    #!/bin/sh
    mkdir -p /var/log/nginx
    ${pkgs.nginx}/bin/nginx -c ${config.home.homeDirectory}/.config/nginx/frps.conf -g 'daemon off;'
  '';
in {
  config = {
    home = {
      packages = with pkgs; [
        nginx
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/nginx/frps.enc.conf";
          to = ".config/nginx/frps.conf";
        } {
          from = "secrets/.config/nginx/home-cert.enc.pem";
          to = ".config/nginx/home-cert.pem";
        } {
          from = "secrets/.config/nginx/home-cert.enc.key";
          to = ".config/nginx/home-cert.key";
        }];
      };
      pm2 = {
        services = [{
          name = "nginx";
          script = script;
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };

  config.home.file = {
    ".config/nginx/50x.html".source = ./50x.html;
  };
}
