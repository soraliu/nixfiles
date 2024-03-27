{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    app = "Hiddify";
    version = "1.0.0";

    src = fetchurl {
      url = "https://github.com/hiddify/hiddify-next/releases/download/v${version}/Hiddify-MacOS.dmg";
      hash = "sha256-Nd+tm9Ik4Fguag0qDdcn+nnDgk+q1xY3HeY64Cv1zIc=";
    };
  };
  filter = writeText "rclone-filters.txt" ''
# NOTICE: If you make changes to this file you MUST do a --resync run.
- *.log
  '';
in  {
  config = {
    home.packages = [ app ];

    programs = {
      rclone = {
        syncPaths = [{
          inherit filter;

          local = (builtins.getEnv "HOME") + "/Library/Application Support/app.hiddify.com";
          remote = "gdrive:Sync/Config/Darwin/app.hiddify.com";
        }];
      };
    };
  };
}
