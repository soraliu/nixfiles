{ pkgs, unstablePkgs, lib, config, ... }:
let
  cfg = config.programs.pm2;
  services = cfg.services;
  pathToConfig = pkgs.writeText "pm2.config.js" ''
    module.exports = {
      apps : ${builtins.toJSON services}
    }
  '';
in
{
  # imports = builtins.filter (el: el != null) [
  #   (lib.mkIf cfg.enable ../../home/modules/lang/nodejs.nix)
  # ];
  imports = [
    ../../home/modules/lang/nodejs.nix
  ];


  options.programs.pm2 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable pm2.";
    };
    services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = [{
        name = "rclone";
        script = "path/to/script";
        interpreter = "${pkgs.zsh}/bin/zsh";
        autorestart = false;
        cron_restart = "*/1 * * * *";
      }];
      description = lib.mdDoc "Run daemons";
    };
  };

  config.home = with lib; mkIf (cfg.enable && (length services > 0)) {
    packages = with pkgs; [ ];


    activation.initPm2 = hm.dag.entryAfter [ "initVolta" ] ''
      ${unstablePkgs.volta}/bin/volta run npm i -g pm2

      pm2_bin=~/.volta/bin/pm2

      set +e
      $pm2_bin delete all 2>/dev/null
      set -e

      $pm2_bin start ${pathToConfig}
      $pm2_bin update
    '';
  };
}
