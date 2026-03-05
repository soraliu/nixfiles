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
    ./modules/ai/cc

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
    dust # modern du alternative with intuitive output, Github: https://github.com/bootandy/dust
    gdu # fast disk usage analyzer with TUI, Github: https://github.com/dundee/gdu
    rsync # fast incremental file transfer, Github: https://github.com/WayneD/rsync
    yazi # modern terminal file manager, replaces joshuto, Github: https://github.com/sxyazi/yazi
    pandoc # universal document converter, replaces catdoc, Github: https://github.com/jgm/pandoc
    exiftool # used by yazi preview
    chafa # modern terminal graphics, replaces ueberzug/catimg, Github: https://github.com/hpjansson/chafa
    bat # like cat, but supports syntax highlighting, Github: https://github.com/sharkdp/bat

    # network
    dog # modern DNS client, replaces dogdns, Github: https://github.com/ogham/dog
    bandwhich # show network usage by process, need be executed by `sudo bandwhich`, Github: https://github.com/imsnif/bandwhich
    htop-vim # better top, Github: https://github.com/KoffeinFlummi/htop-vim

    # doc
    tldr # community-maintained help pages, Github: https://github.com/tldr-pages/tldr

    # json
    jq # jq format
    gojq # high-performance jq alternative in Go, Github: https://github.com/itchyny/gojq

    # container
    docker-client # docker cli

    # pw
    bitwarden-cli # Bitwarden CLI

    # shell
    comma # run software without installing it (need nix-index), Github: https://github.com/nix-community/comma
  ]) ++ (with unstablePkgs; []));

  home.sessionVariables = {
    BAT_THEME = "Coldark-Dark"; # used by `bat`
    PATH = if isDarwin then "${commonPath}:${darwinPath}:$PATH" else "${commonPath}:$PATH";
  };
}
