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
          from = "secrets/.config/nginx/frps-drive.enc.conf";
          to = ".config/nginx/frps.conf";
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
