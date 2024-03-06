{ pkgs, ... }: {
  home.packages = with pkgs; [
    gnupg
    pinentry.curses
  ];
}
