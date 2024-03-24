{ pkgs, ... }: {
  imports = [
    ../../../fs/sops
  ];

  config = {
    home.packages = with pkgs; [
      pet
    ];

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
