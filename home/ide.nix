{ lib, pkgs, unstablePkgs, system, ... }:
let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = [
    ./base.nix

    ./modules/ai/shell-gpt

    ./modules/ide

    ./modules/lang/clang.nix
    ./modules/lang/nodejs.nix
    ./modules/lang/python.nix
    ./modules/lang/go.nix
    ./modules/lang/lua.nix
    ./modules/lang/rust.nix
    ./modules/lang/db.nix

    ./modules/network/clash-meta

    (lib.mkIf isDarwin ./modules/darwin)
  ];

  home.packages = (with pkgs; [
    # fs
    dua # du alternative, `dua i` can also delete files
    rsync # fast incremental file transfer, Github: https://github.com/WayneD/rsync
    joshuto # ternimal file browser
    catdoc # used by joshuto preview
    exiftool # used by joshuto preview
    ueberzug # show images for joshuto
    bat # like cat, but supports syntax highlighting, Github: https://github.com/sharkdp/bat
    catimg # prints images in terminal, Github: https://github.com/posva/catimg

    # process
    htop-vim # better top, Github: https://github.com/KoffeinFlummi/htop-vim

    # network
    wrk # API pressure test tool
    dogdns # dig alternative
    bandwhich # show network usage by process, need be executed by `sudo bandwhich`, Github: https://github.com/imsnif/bandwhich

    # doc
    tldr # community-maintained help pages, Github: https://github.com/tldr-pages/tldr

    # json
    jq # jq format

    # container
    docker # docker cli

    # shell
    comma # run software without installing it (need nix-index), Github: https://github.com/nix-community/comma
  ]) ++ (with unstablePkgs; [
    bitwarden-cli # secret management
  ]);

  home.sessionVariables = {
    BAT_THEME = "Coldark-Dark"; # used by `bat`
    PATH = "$NODEJS_PATH/bin:$GOPATH/bin:$PATH";
  };
}
