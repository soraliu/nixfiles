{ lib, pkgs, unstablePkgs, system, ... }:
let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
  commonPath = "$HOME/.volta/bin:$GOPATH/bin:$HOME/.local/bin";
  darwinPath = "/opt/homebrew/bin";
in
{
  imports = builtins.filter (el: el != "") [
    ./base.nix

    ./modules/ai/shell-gpt

    ./modules/ide

    ./modules/lang/nodejs.nix
    ./modules/lang/python.nix
    ./modules/lang/android.nix
    ./modules/lang/go.nix
    ./modules/lang/lua.nix
    ./modules/lang/rust.nix
    ./modules/lang/db.nix

    ./modules/network/clash-meta
    ./modules/network/nebula

    ./modules/cloud

    (if isDarwin then ./modules/darwin else "")
  ];

  home.packages = builtins.filter (el: el != "") ((with pkgs; [
    # fs
    dua # du alternative, `dua i` can also delete files
    rsync # fast incremental file transfer, Github: https://github.com/WayneD/rsync
    joshuto # ternimal file browser
    catdoc # used by joshuto preview
    exiftool # used by joshuto preview
    (if !isDarwin then ueberzug else "") # show images for joshuto (Linux only)
    bat # like cat, but supports syntax highlighting, Github: https://github.com/sharkdp/bat
    catimg # prints images in terminal, Github: https://github.com/posva/catimg

    # process
    htop-vim # better top, Github: https://github.com/KoffeinFlummi/htop-vim

    # network
    hey
    dogdns # dig alternative
    bandwhich # show network usage by process, need be executed by `sudo bandwhich`, Github: https://github.com/imsnif/bandwhich

    # doc
    tldr # community-maintained help pages, Github: https://github.com/tldr-pages/tldr

    # json
    jq # jq format

    # container
    docker-client # docker cli

    # shell
    comma # run software without installing it (need nix-index), Github: https://github.com/nix-community/comma
  ]) ++ (with unstablePkgs; []));

  home.sessionVariables = {
    BAT_THEME = "Coldark-Dark"; # used by `bat`
    PATH = if isDarwin then "${commonPath}:${darwinPath}:$PATH" else "${commonPath}:$PATH";
  };
}
