{ pkgs, lib, config, ... }: {
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
          script = "${pkgs.nginx}/bin/nginx";
          args = "-c ${config.home.homeDirectory}/.config/nginx/frps.conf -g 'daemon off;'";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };

  config.home.file = {
    ".config/nginx/50x.html".source = ./50x.html;
  };
  config.home.activation.initNginx = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p /var/log/nginx
  '';
}
