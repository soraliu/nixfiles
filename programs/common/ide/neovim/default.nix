{ ... }: {

  imports = [
    # ./coc.nix
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    extraLuaConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./lazy.lua)
      (builtins.readFile ./keymap.lua)          # Keymap preset(Using folke/which-key.nvim)

      (builtins.readFile ./theme.lua)           # Theme palette
      (builtins.readFile ./nvim-tree.lua)       # Sidebar
      (builtins.readFile ./telescope.lua)       # Fuzzy Search
      (builtins.readFile ./lsp.lua)             # LSP
      (builtins.readFile ./treesitter.lua)      # Syntax highlight
      (builtins.readFile ./lualine.lua)         # Status line
      (builtins.readFile ./bufferline.lua)      # Buffer line
      (builtins.readFile ./nvim-autopairs.lua)  # Auto pair symbols
      (builtins.readFile ./improvement.lua)     # Improvements of using neovim

      (builtins.readFile ./lazy-post.lua)       # Execute lazy.nvim setup, this line must be at the end of all lazy.nvim plugins Lua config
    ];

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./base.vim)
    ];
  };
}
