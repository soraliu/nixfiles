{ pkgs, ... }: {
  programs.gpg = {
    enable = true;
  };
  services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    pinentryFlavor = "curses";
  };
  home.packages = with pkgs; [
    pinentry.curses
  ];
}
