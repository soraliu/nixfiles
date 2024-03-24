{ unstablePkgs, ... }: let
in {
  config = {
    home = {
      packages = with unstablePkgs; [
        sing-box
      ];
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/sing-box/config.enc.json";
          to = ".config/sing-box/config.json";
        }];
      };
    };
  };
}
