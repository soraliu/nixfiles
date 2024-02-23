{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # makefile
    libgcc              # provide `make` command and c++ compiler

    # version control
    git-extras          # extra git alias
    bfg-repo-cleaner    # big file cleaner for git

    # network
    inetutils           # provide: `telnet`, `ftp`, `hostname`, `ifconfig`, `traceroute`, `ping`, etc
    wget                # wget
    curl                # curl
    bandwhich           # show network usage by process
    dogdns              # dig alternative

    # search
    ripgrep           # rg

    # package manager
    comma               # run software without installing it (need nix-index)

    # files
    joshuto             # ternimal file browser
    catdoc              # used by joshuto preview
    exiftool            # used by joshuto preview
    ueberzug            # show images for joshuto
    fd                  # better find
    dua                 # du alternative, `dua i` can also delete files
    # TODO: get familiar with these commands
    bup                 # dedup backup tool

    # system
    procs               # better ps

    # string
    sd                  # sed alternative
  ];
}
