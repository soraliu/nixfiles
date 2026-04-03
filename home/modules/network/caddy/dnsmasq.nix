{ pkgs, config, lib, ... }: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in {
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
      # Darwin 由 launchd.daemons（systems/darwin.nix）以 root 管理，无需 pm2
      pm2 = lib.mkIf (!isDarwin) {
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
