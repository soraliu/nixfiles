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

      (builtins.readFile ./theme.lua)
      (builtins.readFile ./startify.lua)
      # (builtins.readFile ./nerdtree.lua)
      (builtins.readFile ./nvim-tree.lua)       # Sidebar
      (builtins.readFile ./telescope.lua)       # Fuzzy Search

      (builtins.readFile ./ansiesc.lua)         # Show special chars
      (builtins.readFile ./treesitter.lua)      # Syntax highlight

      # (builtins.readFile ./airline.lua)
      (builtins.readFile ./lualine.lua)         # Status line
      (builtins.readFile ./bufferline.lua)      # Buffer line

      (builtins.readFile ./lsp.lua)
      (builtins.readFile ./fzf.lua)

      (builtins.readFile ./lazy-post.lua) # Execute lazy.nvim setup, this line must be at the end of all lazy.nvim plugins Lua config
    ];

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./base.vim)
      # (builtins.readFile ./startify.vim)
      # (builtins.readFile ./nerdtree.vim)
      (builtins.readFile ./airline.vim)
      (builtins.readFile ./ansiesc.vim)
    ];
  };
}
