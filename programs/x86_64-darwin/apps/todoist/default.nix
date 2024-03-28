{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "todoist";
    version = "8.18.0";

    src = fetchurl {
      url = "https://drive.soraliu.dev/0:/Software/Darwin/Todoist/${version}/Todoist.dmg";
      hash = "sha256-T7e9yn9k9Xr1SSOHkHoVRjlekaf0yrcBHuBE0c0iVtU=";
    };
  };
in  {
  config = {
    home.packages = [ app ];
  };
}
