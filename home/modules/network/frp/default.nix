{ pkgs, config, ... }: {
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
          to = ".config/frp/frps.toml";
        }];
      };
      pm2 = {
        services = [{
          name = "frps";
          script = "${pkgs.frp}/bin/frps";
          args = "-c ${config.home.homeDirectory}/.config/frp/frps.toml";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
