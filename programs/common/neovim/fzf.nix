{ config, pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = fzf-vim;
      config = builtins.readFile ./fzf.vim;
    }
  ];
}
