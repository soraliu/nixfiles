{ pkgs, ... }: with pkgs; let
  app = import ../app.nix rec {
    inherit pkgs;

    pname = "clashx";
    version = "1.3.12";

    src = fetchzip {
      name = "ClashX.Meta.app";
      url = "https://github.com/MetaCubeX/ClashX.Meta/releases/download/v${version}/ClashX.Meta.macOS.12.0+.zip";
      hash = "sha256-ZqicqlRq5bFMHWBsURvA8WThZrXsl7ZuXdc2Q/Lp3/s=";
    };
  };
in  {
  config = {
    home.packages = [ app ];

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/clash/config.enc.yaml";
          to = ".config/clash.meta/config.yaml";
        }];
      };
    };
  };
}
