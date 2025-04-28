{ pkgs, lib, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        pet
      ];

      activation.initPet = lib.hm.dag.entryAfter ["linkGeneration"] ''
        path_to_config="${builtins.getEnv "HOME"}/.config/pet"
        mkdir -p "$path_to_config"
        touch "$path_to_config/snippet.toml"
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
