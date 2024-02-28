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
      (builtins.readFile ./nvim-tree.lua)
      (builtins.readFile ./airline.lua)
      (builtins.readFile ./ansiesc.lua)
      (builtins.readFile ./syntax.lua)
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
