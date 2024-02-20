{ config, pkgs, ... }: {
  programs.neovim.coc = {
    enable = true;
    pluginConfig = builtins.readFile ./config/coc.vim;
    settings = {
    };
  };

  programs.neovim.plugins = with pkgs.vimPlugins; [
    coc-rust-analyzer
  ];

  home.packages = with pkgs; [
    rust-analyzer
  ];
}
