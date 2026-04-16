{ pkgs, unstablePkgs, lib, config, isMobile, ... }: {

  imports = [
    ../search/ripgrep
  ];

  home.packages = [ pkgs.glow ];

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    extraLuaConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./lazy.lua)
      (builtins.readFile ./keymap.lua) # Keymap preset(Using folke/which-key.nvim)

      (builtins.readFile ./theme.lua) # Theme palette
      (builtins.readFile ./nvim-tree.lua) # Sidebar


      (builtins.readFile ./telescope.lua) # Fuzzy Search
      ''
        vim.cmd([[
          let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/${if pkgs.stdenv.isDarwin then "libsqlite3.dylib" else "libsqlite3.so"}'
        ]])
        -- glow binary path for glow.nvim
        vim.g.glow_binary_path = '${lib.getExe pkgs.glow}'
      ''


      (builtins.readFile ./snippet.lua) # Snippet
      (builtins.readFile ./lsp.lua) # LSP
      (builtins.readFile ./marks.lua) # Marks
      (builtins.readFile ./ai.lua) # Copilot & ChatGPT
      (builtins.readFile ./treesitter.lua) # Syntax highlight
      (builtins.readFile (pkgs.replaceVars ./lualine.lua {
        branch = if isMobile then "" else "branch";
        encoding = if isMobile then "" else "encoding";
        fileformat = if isMobile then "" else "fileformat";
      })) # Status linelunixdefault
      (builtins.readFile ./bufferline.lua) # Buffer line
      (builtins.readFile ./nvim-autopairs.lua) # Auto pair symbols
      (builtins.readFile ./git.lua) # Git Related
      (builtins.readFile ./improvement.lua) # Improvements of using neovim

      (builtins.readFile ./lazy-post.lua) # Execute lazy.nvim setup, this line must be at the end of all lazy.nvim plugins Lua config

      (builtins.readFile ./fixup.lua) # Fix some weird config
      (builtins.readFile ./performance.lua) # Performance optimization for large files
    ];

    extraConfig = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./base.vim)
    ];
  };

  home.activation.copyLazyLock =
    let
      src = ./lazy/lazy-lock.json;
      target = "${config.home.homeDirectory}/.config/nvim/lazy-lock.json";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $(dirname ${target})
      cp ${src} ${target}
      chmod +w ${target}
    '';

  home.activation.installWin32yank = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
      WIN32YANK_DIR="$HOME/.local/bin"
      WIN32YANK_PATH="$WIN32YANK_DIR/win32yank.exe"

      if [[ ! -f "$WIN32YANK_PATH" ]]; then
        echo "Installing win32yank.exe for WSL clipboard support..."
        mkdir -p "$WIN32YANK_DIR"
        ${pkgs.curl}/bin/curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
        ${pkgs.unzip}/bin/unzip -o /tmp/win32yank.zip -d /tmp/
        mv /tmp/win32yank.exe "$WIN32YANK_PATH"
        chmod +x "$WIN32YANK_PATH"
        rm -f /tmp/win32yank.zip /tmp/LICENSE /tmp/README.md
        echo "win32yank.exe installed to $WIN32YANK_PATH"
      fi
    fi
  '';
}
