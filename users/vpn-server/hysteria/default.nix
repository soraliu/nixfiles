{ unstablePkgs, config, ... }: let
in {
  imports = [
    ../../../../programs/common/fs/sops
    ../../../../programs/common/process/pm2
  ];

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
