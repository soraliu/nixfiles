{ pkgs, ... }: with pkgs; let
  filter = writeText "rclone-filters.txt" ''
# NOTICE: If you make changes to this file you MUST do a --resync run.
+ karabiner.json
- **
  '';
in  {
  config = {
    programs = {
      rclone = {
        syncPaths = [{
          inherit filter;

          local = (builtins.getEnv "HOME") + "/.config/karabiner";
          remote = "gdrive:Sync/Config/Darwin/karabiner";
        }];
      };
    };
  };
}
