{ pkgs, ... }: {
  programs.neovim.coc = {
    enable = true;
    pluginConfig = builtins.readFile ./coc.vim;
    settings = builtins.fromJSON (builtins.readFile ./coc-setings.json);
  };

  programs.neovim.plugins = with pkgs.vimPlugins; [
    coc-rust-analyzer
  ];

  home.packages = with pkgs; [
    rust-analyzer
  ];
}
