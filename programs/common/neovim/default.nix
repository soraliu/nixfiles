{ config, pkgs, ... }: {

  imports = [
    ./theme.nix
    ./coc.nix
    ./nerdtree.nix
    ./airline.nix
    ./ansiesc.nix
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
