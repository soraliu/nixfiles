{ config, pkgs, ... }: {

  imports = [
    ./theme.nix
    ./startify.nix
    ./nerdtree.nix
    ./airline.nix
    ./ansiesc.nix
    ./coc.nix
    ./fzf.nix
  ];

  home.packages = with pkgs; [
    nixd
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
