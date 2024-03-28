{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "sublime";
    version = "4169";

    src = fetchzip {
      name = "Sublime.app";
      url = "https://drive.soraliu.dev/0:/Software/Darwin/Sublime%20Text/${version}/Sublime%20Text.zip";
      hash = "sha256-tLOgCIfP3wtjim2aPj3UwWKrgq2E9/f20P/7a97UCaw=";
    };
  };
in {
  config = {
    home.packages = [ app ];
  };
}
