{ pkgs, ... }: let
  app = with pkgs; callPackage ./app.nix {  inherit stdenvNoCC fetchurl undmg; };
in  {
  imports = [
    ../../common/fs/rclone
  ];

  config = {
    home.packages = [ app ];

    programs = {
      rclone = {
        syncPaths = [{
          local = (builtins.getEnv "HOME") + "/Library/Application Support/app.hiddify.com";
          remote = "gdrive:Sync/Config/Darwin/app.hiddify.com";
          filter = ./rclone-filters.txt;
        }];
      };
    };
  };
}
