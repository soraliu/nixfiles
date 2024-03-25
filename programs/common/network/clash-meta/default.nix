{ pkgs, unstablePkgs, lib, config, useProxy, ... }: let
  cfg = config.programs.clash;
  yacd = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "yacd";
    version = "0.3.8";

    src = pkgs.fetchFromGitHub {
      owner = "haishanh";
      repo = "yacd";
      rev = "09eb9389a7109eafd35118cbf7c2ac0860190b01";
      hash = "sha256-SaVsY2kGd+v6mmjwXAHSgRBDBYCxpWDYFysCUPDZjlE=";
    };

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  });
  metacubexd = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "metacubexd";
    version = "1.136.0";

    src = pkgs.fetchFromGitHub {
      owner = "MetaCubeX";
      repo = "metacubexd";
      rev = "630ffcc12a71e69edf647c1439dcceaaf18d2d7b";
      hash = "sha256-v6aWhfegllqgDRdTxtMnXPzziNu1HL3XAyZOnhrInvk=";
    };

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  });
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
      file = {
        ".config/clash/ui/yacd".source = yacd;
        ".config/clash/ui/metacubexd".source = metacubexd;
      };
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
          exp_backoff_restart_delay = 100;
        }];
      };
    };
  };
}
