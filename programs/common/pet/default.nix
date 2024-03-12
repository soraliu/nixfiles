{ pkgs, lib, config, ... }: {
  config = {
    home.packages = with pkgs; [
      pet
    ];

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/pet/config.toml.enc";
          to = ".config/pet/config.toml";
        }];
      };
    };

    home.activation.initPetSnippets = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.pet}/bin/pet sync
    '';
  };
}
