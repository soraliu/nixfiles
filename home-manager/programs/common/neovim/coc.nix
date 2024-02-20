{ config, pkgs, ... }: {
  programs.neovim.coc = {
    enable = true;
    pluginConfig = builtins.readFile ./config/coc.vim;
    settings = {
    };
  };
  programs.neovim.plugins = with pkgs.vimPlugins; [
    coc-rust-analyzer
    coc-css
    coc-emoji
    coc-eslint
    coc-git
    coc-html
    coc-json
    coc-lists
    coc-prettier
    coc-pyright
    coc-sh
    coc-snippets
    coc-solidity
    coc-stylelintplus
    coc-svg
    coc-swagger
    coc-tsserver
    coc-word
    coc-yaml
    coc-yank
  ];
  home.packages = with pkgs; [
    rust-analyzer
  ];
}
