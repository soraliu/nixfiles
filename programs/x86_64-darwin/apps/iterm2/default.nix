{ unstablePkgs, ... }: with unstablePkgs; let
in  {
  config = {
    home.packages = [
      iterm2
    ];

    programs = {
      rclone = {
        syncPaths = [{
          remote = "gdrive:Sync/Config/Darwin/com.googlecode.iterm2";
        }];
      };
    };
  };
}
