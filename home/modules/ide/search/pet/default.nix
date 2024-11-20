{ pkgs, lib, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        pet
      ];

      activation.initPet = lib.hm.dag.entryAfter ["linkGeneration"] ''
        ${pkgs.pet}/bin/pet sync
      '';
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/pet/config.enc.toml";
          to = ".config/pet/config.toml";
        }];
      };
    };
  };
}
