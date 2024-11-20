{ unstablePkgs, config, ... }: let
in {
  config = {
    home = {
      packages = with unstablePkgs; [
        hysteria
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/hysteria/config.enc.yaml";
          to = ".config/hysteria/config.yaml";
        } {
          from = "secrets/.config/hysteria/bing.com.enc.crt";
          to = ".config/hysteria/bing.com.crt";
        } {
          from = "secrets/.config/hysteria/bing.com.enc.key";
          to = ".config/hysteria/bing.com.key";
        }];
      };
      pm2 = {
        services = [{
          name = "hysteria";
          script = "${unstablePkgs.hysteria}/bin/hysteria";
          args = "server -c ${config.home.homeDirectory}/.config/hysteria/config.yaml";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
