{ pkgs, lib, config, useProxy ? false, ... }: let
  cfg = config.programs.clash;
  app = pkgs.callPackage ./app.nix { inherit pkgs; };
in {
  options.programs.clash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = useProxy;
      example = true;
      description = lib.mdDoc "Whether to enable clash premium.";
    };
  };

  config.home = with lib; mkIf cfg.enable {
    packages = with pkgs; [
      app
    ];
  };
}
