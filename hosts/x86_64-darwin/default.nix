{ config, pkgs, ... }: let
  fonts = with pkgs; [
    (fetchurl {
      url = "https://drive.soraliu.dev/0:/Fonts/SauceCodeProNerdFontMono-MediumItalic.ttf";
      hash = "sha256-N9L57FiiwlO2vzEMP6eLWLUW9omvfx812AEWgg2cd2c=";
    })
    (fetchurl {
      url = "https://drive.soraliu.dev/0:/Fonts/SauceCodeProNerdFontMono-Medium.ttf";
      hash = "sha256-wE9zp+h6hiO8qq5DXYsfEt6NGXdigCxUQbjzNGWFjhY=";
    })
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

  fonts.fontDir.enable = true;
  fonts.fonts = fonts;
}
