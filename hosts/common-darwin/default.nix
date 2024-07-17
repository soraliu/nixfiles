{ config, pkgs, ... }: let
  font = with pkgs; import ../common/font.nix { inherit fetchurl; };
  fonts = with pkgs; [
    font.medium
    font.mediumItalic
  ];
in {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.settings.trusted-users = [ "@staff" ];
  nixpkgs.config.allowUnfree = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  system.defaults.NSGlobalDomain.InitialKeyRepeat = 12;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;

  fonts.fontDir.enable = true;
  fonts.fonts = fonts;
}
