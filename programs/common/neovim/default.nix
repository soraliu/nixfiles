{ config, pkgs, ... }: {

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

      (builtins.readFile ./keymap.lua)          # Keymap preset

      (builtins.readFile ./theme.lua)           # Theme palette
      (builtins.readFile ./startify.lua)        # Welcome page
      (builtins.readFile ./nvim-tree.lua)       # Sidebar
      (builtins.readFile ./telescope.lua)       # Fuzzy Search

      (builtins.readFile ./lsp.lua)             # LSP
      (builtins.readFile ./treesitter.lua)      # Syntax highlight

      (builtins.readFile ./improvement.lua)     # Improvements of using neovim

      # (builtins.readFile ./airline.lua)
      (builtins.readFile ./lualine.lua)         # Status line
      (builtins.readFile ./bufferline.lua)      # Buffer line

      (builtins.readFile ./ansiesc.lua)         # Show special chars

      (builtins.readFile ./lazy-post.lua)       # Execute lazy.nvim setup, this line must be at the end of all lazy.nvim plugins Lua config
    ];

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./base.vim)
      # (builtins.readFile ./startify.vim)
      # (builtins.readFile ./nerdtree.vim)
      # (builtins.readFile ./airline.vim)
      (builtins.readFile ./ansiesc.vim)
    ];
  };
}
