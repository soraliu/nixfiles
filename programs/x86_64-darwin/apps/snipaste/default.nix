{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "snipaste";
    version = "2.8.6";

    src = fetchurl {
      url = "https://drive.soraliu.dev/0:/Software/Darwin/Snipaste/${version}/Snipaste.dmg";
      hash = "sha256-tvamAg7/IyjO3510j7rmZ60baKR6tDX2S19LsFPlSZk=";
    };
  };
  filter = writeText "rclone-filters.txt" ''
# NOTICE: If you make changes to this file you MUST do a --resync run.
+ config.ini
- **
  '';
in  {
  config = {
    home.packages = [ app ];

    programs = {
      rclone = {
        syncPaths = [{
          inherit filter;

          local = (builtins.getEnv "HOME") + "/.snipaste";
          remote = "gdrive:Sync/Config/Darwin/.snipaste";
        }];
      };
    };
  };
}
