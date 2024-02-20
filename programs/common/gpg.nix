{ pkgs, ... }: {
  programs.gpg = {
    enable = true;
  };
  services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    pinentryFlavor = "tty";
  };
}
