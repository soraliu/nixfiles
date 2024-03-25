{ pkgs, unstablePkgs, lib, config, useProxy, ... }: let
  cfg = config.programs.clash;
in {
  imports = [
    ../../process/pm2
  ];

  options.programs.clash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = useProxy;
      example = true;
      description = lib.mdDoc "Whether to enable clash premium.";
    };
  };

  config = with lib; mkIf cfg.enable {
    home = {
      packages = with unstablePkgs; [
        mihomo
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/clash/config.enc.yaml";
          to = ".config/clash/config.yaml";
        }];
      };
      pm2 = {
        services = [{
          name = "clash-meta";
          script = "${unstablePkgs.mihomo}/bin/mihomo";
          args = "-d ${config.home.homeDirectory}/.config/clash";
        }];
      };
    };
  };
}
