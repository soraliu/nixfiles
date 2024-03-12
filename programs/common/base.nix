{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # doc
    tldr                                      # community-maintained help pages                                                # Github: https://github.com/tldr-pages/tldr

    # makefile
    gcc9                                      # provide `make` command and c++ compiler

    # # network
    inetutils                                 # provide: `telnet`, `ftp`, `hostname`, `ifconfig`, `traceroute`, `ping`, etc
    wget                                      # wget
    curl                                      # curl
    dogdns                                    # dig alternative
    bandwhich                                 # show network usage by process, need be executed by `sudo bandwhich`
                                                # Github: https://github.com/imsnif/bandwhich

    # package manager
    comma                                     # run software without installing it (need nix-index)
                                                # Github: https://github.com/nix-community/comma

    # # files
    rsync                                     # fast incremental file transfer
                                                # Github: https://github.com/WayneD/rsync
    joshuto                                   # ternimal file browser
    catdoc                                    # used by joshuto preview
    exiftool                                  # used by joshuto preview
    ueberzug                                  # show images for joshuto
    fd                                        # better find
    tree                                      # show dir like a tree
    dua                                       # du alternative, `dua i` can also delete files
    bat                                       # like cat, but supports syntax highlighting
                                                # Github: https://github.com/sharkdp/bat
    catimg                                    # prints images in terminal
                                                # Github: https://github.com/posva/catimg

    # # TODO: get familiar with these commands
    # bup                                       # dedup backup tool

    # system
    htop-vim                                  # better top
                                                # Github: https://github.com/KoffeinFlummi/htop-vim
    unixtools.whereis                         # whereis

    # string
    sd                                        # sed alternative

    # coding
    nodejs_20                                 # nodejs, npm
    # python3                                   # python3
    # python311Packages.pip                     # pip3
    # rustc                                     # rust
    # cargo                                     # rust package maanger
  ];

  home.sessionVariables = {
    PATH = "${pkgs.nodejs_20}/bin:$PATH";

    BAT_THEME = "Coldark-Dark";
  };
}
