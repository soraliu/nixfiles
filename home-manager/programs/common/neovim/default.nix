{ config, pkgs, ... }: {
  imports = [
    ./coc.nix
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    coc = {
      enable = true;

    };

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./config/vim-plug.vim)
    ];
  };

  home = {
    sessionVariables.EDITOR = "nvim";
  };
}
