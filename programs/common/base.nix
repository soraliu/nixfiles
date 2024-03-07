{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # makefile
    gcc9                # provide `make` command and c++ compiler

    # # network
    # inetutils           # provide: `telnet`, `ftp`, `hostname`, `ifconfig`, `traceroute`, `ping`, etc
    # wget                # wget
    # curl                # curl
    # bandwhich           # show network usage by process
    # dogdns              # dig alternative
    #
    # # package manager
    # comma               # run software without installing it (need nix-index)
    #
    # # files
    # joshuto             # ternimal file browser
    # catdoc              # used by joshuto preview
    # exiftool            # used by joshuto preview
    # ueberzug            # show images for joshuto
    # fd                  # better find
    # dua                 # du alternative, `dua i` can also delete files
    # # TODO: get familiar with these commands
    # bup                 # dedup backup tool
    #
    # # system
    # procs               # better ps
    # unixtools.whereis   # whereis
    #
    # # string
    # sd                  # sed alternative
    #
    # # coding
    # nodejs_20           # nodejs, npm
    # python3             # python3
    # python311Packages.pip   # pip3
    # rustc               # rust
    # cargo               # rust package maanger

  ];

  home.sessionVariables = {
    PATH = "${pkgs.nodejs_20}/bin:$PATH";
  };
}
