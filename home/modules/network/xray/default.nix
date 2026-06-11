{ unstablePkgs, config, ... }: {
  config = {
    home = {
      packages = with unstablePkgs; [
        xray
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/xray/config.enc.json";
          to = ".config/xray/config.json";
        }];
      };

      pm2 = {
        services = [{
          name = "xray";
          script = "${unstablePkgs.xray}/bin/xray";
          args = "run -config ${config.home.homeDirectory}/.config/xray/config.json";
          interpreter = "none";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
