{ pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-lspconfig;
      type = "lua";
      config = builtins.readFile ./lsp.lua;
    }
  ];
}
