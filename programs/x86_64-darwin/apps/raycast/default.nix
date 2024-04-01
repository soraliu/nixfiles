{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "raycast";
    version = "1.70.0";

    src = fetchurl {
      name = "Raycast.dmg";
      url = "https://raycast-releases-9b5ab5b505ea.herokuapp.com/releases/${version}/download";
      hash = "sha256-+8P8bTD4I4Se/Ii6/oHiqzqgqkrf4QNQ9RL/l9MRuO0=";
    };
  };
  filter = writeText "rclone-filters.txt" ''
# NOTICE: If you make changes to this file you MUST do a --resync run.
- Updates/**
- NodeJS/**
- RaycastWrapped/**
- extensions/**
- raycast-activities-*
  '';
in  {
  imports = [
    ../../../common/fs/sops
  ];

  config = {
    home.packages = [ app ];

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/raycast/database_key.enc";
          to = ".config/raycast/database_key";
        }];
      };

      rclone = {
        syncPaths = [{
          inherit filter;

          local = (builtins.getEnv "HOME") + "/Library/Application Support/com.raycast.macos";
          remote = "gdrive:Sync/Config/Darwin/com.raycast.macos";
        }];
      };
    };
  };
}
