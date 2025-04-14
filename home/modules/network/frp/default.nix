{ pkgs, unstablePkgs, lib, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        frp
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/frp/frps.enc.toml";
          to = ".config/frp/frps.yaml";
        }];
      };
      pm2 = {
        services = [{
          name = "frps";
          script = "${pkgs.frp}/bin/hysteria";
          args = "-c ${config.home.homeDirectory}/.config/frp/frps.toml";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
