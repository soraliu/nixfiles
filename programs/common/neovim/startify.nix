{ config, pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = vim-startify;
      config = builtins.readFile ./startify.vim;
    }
  ];
}
