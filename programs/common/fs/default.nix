{ pkgs, unstablePkgs, ... }: {
  imports = [
    # file sync
    ./rclone
    # encrypt & decrypt
    ./sops
  ];

  home.packages = (with pkgs; [
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
  ]) ++ (with unstablePkgs; [
  ]);

  home.sessionVariables = {
    BAT_THEME = "Coldark-Dark"; # used by `bat`
  };
}
