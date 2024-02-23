{ config, pkgs, ... }: {

  imports = [
    ./theme.nix               # theme
    ./startify.nix            # show welcome page
    ./nerdtree.nix            # sidebar
    ./airline.nix             # show tabs on the top
    ./ansiesc.nix             # conceal Ansi escape sequences but will cause subsequent text to be colored
    # ./coc.nix
    ./lsp.nix                 # LSP
    ./fzf.nix                 # search files, commands, buffers, etc
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
