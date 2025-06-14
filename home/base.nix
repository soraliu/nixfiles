{ lib, config, pkgs, unstablePkgs, ... }: {
  imports = [
    ../pkgs/sops
    ../pkgs/pm2
    ../pkgs/linker
    ../pkgs/rclone

    ./modules/home-manager
  ];


  home.packages = (with pkgs; [
    # utils
    coreutils

    # fs
    findutils # find, xargs
    gnugrep   # GNU grep
    fd        # better find
    tree      # show dir like a tree
    zip unzip # zip, unzip

    # network
    inetutils # provide: `telnet`, `ftp`, `hostname`, `ifconfig`, `traceroute`, `ping`, etc
    wget      # wget
    curl      # curl
    iperf3    # speed bandwidth test

    # makefile
    gnumake   # provide make
    just      # Justfile

    # string
    sd        # sed alternative

    # sign
    gnupg   # GnuPG, provide: `gpg`, `gpg2`, `gpgconf`, `gpg-connect-agent`, etc
  ]) ++ (with unstablePkgs; [
  ]);

  home.activation.initJust = lib.mkIf config.programs.zsh.enable (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ${config.programs.zsh.completionsDir}
    ${pkgs.just}/bin/just --completions zsh > ${config.programs.zsh.completionsDir}/_just
  '');
}
