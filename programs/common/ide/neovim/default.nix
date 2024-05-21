{ pkgs, isMobile, ... }: {

  imports = [
    # ./coc.nix
    ../search/ripgrep
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
      ''
      vim.cmd([[
        let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/${if pkgs.stdenv.isDarwin then "libsqlite3.dylib" else "libsqlite3.so"}'
      ]])
      ''


      (builtins.readFile ./lsp.lua)             # LSP
      (builtins.readFile ./marks.lua)           # Marks
      (builtins.readFile ./ai.lua)              # Copilot & ChatGPT
      (builtins.readFile ./treesitter.lua)      # Syntax highlight
      (builtins.readFile (pkgs.substituteAll {
        src = ./lualine.lua;
        branch = if isMobile then "" else "branch";
        encoding = if isMobile then "" else "encoding";
        fileformat = if isMobile then "" else "fileformat";
      })) # Status linelunixdefault
      (builtins.readFile ./bufferline.lua)      # Buffer line
      (builtins.readFile ./nvim-autopairs.lua)  # Auto pair symbols
      (builtins.readFile ./git.lua)             # Git Related
      (builtins.readFile ./improvement.lua)     # Improvements of using neovim

      (builtins.readFile ./lazy-post.lua)       # Execute lazy.nvim setup, this line must be at the end of all lazy.nvim plugins Lua config

      (builtins.readFile ./fixup.lua)           # Fix some weird config
    ];

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./base.vim)
    ];
  };
}
