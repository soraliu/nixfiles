{ pkgs, config, ... }: {
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
          script = "${pkgs.caddy}/bin/caddy";
          args = "run --config ${config.home.homeDirectory}/.config/caddy/Caddyfile";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
