{ config, pkgs, ... }: {

  imports = [
    ./theme.nix
    ./startify.nix
    ./nerdtree.nix
    ./airline.nix
    ./ansiesc.nix
    ./coc.nix
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./default.vim)
    ];
  };
}
