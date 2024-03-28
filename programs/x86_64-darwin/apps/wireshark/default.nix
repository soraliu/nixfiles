{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "wireshark";
    version = "4.2.4";

    src = fetchurl {
      url = "https://2.na.dl.wireshark.org/osx/Wireshark%20${version}%20Intel%2064.dmg";
      hash = "sha256-APbwhlImPUqTJJ/xuo/f8o3haAYYTZ0m4Nuhq4ue1gQ=";
    };
  };
in  {
  config = {
    home.packages = [ app ];
  };
}
