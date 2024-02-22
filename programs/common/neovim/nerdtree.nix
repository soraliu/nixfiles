{ config, pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = nerdtree;
      config = builtins.readFile ./nerdtree.vim;
    }
    nerdtree-git-plugin
    nerdcommenter
    vim-devicons
  ];
}
