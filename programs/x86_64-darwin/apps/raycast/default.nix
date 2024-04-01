{ pkgs, ... }: with pkgs; let
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
