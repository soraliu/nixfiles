{ config, pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = molokai;
      config = builtins.readFile ./theme.vim;
    }
    papercolor-theme
  ];
}
