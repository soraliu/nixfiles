{ pkgs, config, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        dnsmasq
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/dnsmasq/dnsmasq.enc.conf";
          to = ".config/dnsmasq/dnsmasq.conf";
        }];
      };
      pm2 = {
        services = [{
          name = "dnsmasq";
          script = "${pkgs.dnsmasq}/bin/dnsmasq";
          args = "--keep-in-foreground -C ${config.home.homeDirectory}/.config/dnsmasq/dnsmasq.conf";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
