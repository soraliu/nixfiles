{ config, pkgs, ... }: {
  imports = [
    ./coc.nix
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./config/settings.vim)
    ];
  };

  home = {
    sessionVariables.EDITOR = "nvim";
  };
}
