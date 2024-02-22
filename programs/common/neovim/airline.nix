{ config, pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = vim-airline;
      config = builtins.readFile ./airline.vim;
    }
    vim-airline-themes
  ];
}
