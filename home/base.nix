{ lib, config, pkgs, unstablePkgs, ... }: {
  imports = [
    ../pkgs/sops
    ../pkgs/pm2
    ../pkgs/linker
    ../pkgs/rclone
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "23.11";
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.packages = (with pkgs; [
    # fs
    findutils # find, xargs
    gnugrep   # GNU grep
    fd        # better find
    tree      # show dir like a tree

    # network
    inetutils # provide: `telnet`, `ftp`, `hostname`, `ifconfig`, `traceroute`, `ping`, etc
    wget      # wget
    curl      # curl

    # makefile
    gnumake   # provide make
    just      # Justfile

    # string
    sd        # sed alternative
  ]) ++ (with unstablePkgs; [
  ]);

  home.activation.initJust = lib.mkIf config.programs.zsh.enable (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${lib.mkIf config.programs.zsh.enable ''${pkgs.just}/bin/just --completions zsh > ${config.programs.zsh.completionsDir}/_just''}
  '');
}
