{ pkgs, lib, config, ... }: let
  app = with pkgs; callPackage ./app.nix {  inherit lib stdenvNoCC fetchurl undmg; };
in  {
  config = {
    home.packages = [ app ];

    programs = {
      rclone = {
        syncPaths = [{
          local = (builtins.getEnv "HOME") + "/Library/Application Support/com.raycast.macos";
          remote = "gdrive:Sync/Config/Darwin/com.raycast.macos";
          filter = ./rclone-filters.txt;
        }];
      };
    };
  };
}
