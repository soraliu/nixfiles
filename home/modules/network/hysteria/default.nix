{ pkgs, unstablePkgs, lib, config, ... }: let
in {
  config = {
    home = {
      packages = with unstablePkgs; [
        hysteria
      ];

      activation.tuneHysteriaUdpBuffers = lib.hm.dag.entryBefore [ "initPm2" ] ''
        ${pkgs.procps}/bin/sysctl -w \
          net.core.rmem_max=67108864 \
          net.core.wmem_max=67108864 \
          net.core.rmem_default=67108864 \
          net.core.wmem_default=67108864 \
          >/dev/null || true
      '';
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
