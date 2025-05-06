{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "snipaste";
    version = "2.8.6";

    src = fetchurl {
      url = "https://drive.home.soraliu.dev/dav/software/darwin/Snipaste/${version}/Snipaste.dmg";
      hash = "sha256-tvamAg7/IyjO3510j7rmZ60baKR6tDX2S19LsFPlSZk=";
    };
  };
in {
  config.home.packages = [ app ];
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/.snipaste";
    link = (builtins.getEnv "HOME") + "/.snipaste";
  }];
}
