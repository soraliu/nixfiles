{ config, pkgs, unstablePkgs, ... }:
let
  pathToIterm2Config = "$HOME/.config/iterm2/com.googlecode.iterm2";
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.settings.trusted-users = [ "soraliu" "@staff" ];
  nixpkgs.config.allowUnfree = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "right";
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  system.defaults.NSGlobalDomain.InitialKeyRepeat = 12;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;

  system.activationScripts = {
    postUserActivation.text = ''
      defaults write com.googlecode.iterm2 PrefsCustomFolder -string '${pathToIterm2Config}'
    '';
  };

  fonts.packages = with unstablePkgs; [
    nerd-fonts.sauce-code-pro
  ];
}
