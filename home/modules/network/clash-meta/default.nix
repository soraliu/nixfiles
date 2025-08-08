{ pkgs, unstablePkgs, lib, config, useProxy, ... }: let
  cfg = config.programs.clash;
  dashboard = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "clash-dashboard";
    version = "0.0.1";

    srcs = [
      (pkgs.fetchFromGitHub {
        name = "yacd";
        owner = "haishanh";
        repo = "yacd";
        rev = "09eb9389a7109eafd35118cbf7c2ac0860190b01";
        hash = "sha256-SaVsY2kGd+v6mmjwXAHSgRBDBYCxpWDYFysCUPDZjlE=";
      })
      (pkgs.fetchFromGitHub {
        name = "metacubexd";
        owner = "MetaCubeX";
        repo = "metacubexd";
        rev = "630ffcc12a71e69edf647c1439dcceaaf18d2d7b";
        hash = "sha256-v6aWhfegllqgDRdTxtMnXPzziNu1HL3XAyZOnhrInvk=";
      })
    ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  });
in {
  options.programs.clash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = useProxy;
      example = true;
      description = lib.doc "Whether to enable clash premium.";
    };
  };

  config = with lib; mkIf cfg.enable {
    home = {
      packages = with unstablePkgs; [
        mihomo
      ];
      file = {
        ".config/clash/ui".source = dashboard;
      };
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/clash/config-whitelist.enc.yaml";
          to = ".config/clash/config.yaml";
        }];
      };
      pm2 = {
        services = [{
          name = "clash-meta";
          script = "${unstablePkgs.mihomo}/bin/mihomo";
          args = "-d ${config.home.homeDirectory}/.config/clash";
          exp_backoff_restart_delay = 100;
        }];
      };
    };
  };
}
