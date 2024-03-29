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

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  # programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  fonts = {
    inherit fonts;

    fontDir.enable = true;
  };
}
