{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dust # modern du alternative with intuitive output, Github: https://github.com/bootandy/dust
    gdu # fast disk usage analyzer with TUI, Github: https://github.com/dundee/gdu
    rsync # fast incremental file transfer, Github: https://github.com/WayneD/rsync
    yazi # modern terminal file manager, replaces joshuto, Github: https://github.com/sxyazi/yazi
    pandoc # universal document converter, replaces catdoc, Github: https://github.com/jgm/pandoc
    exiftool # used by yazi preview
    chafa # modern terminal graphics, replaces ueberzug/catimg, Github: https://github.com/hpjansson/chafa
    bat # like cat, but supports syntax highlighting, Github: https://github.com/sharkdp/bat
  ];

  home.sessionVariables = {
    BAT_THEME = "Coldark-Dark"; # used by `bat`
  };
}
