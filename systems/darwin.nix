{ config, pkgs, unstablePkgs, homeUser, ... }: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  nix.settings.trusted-users = [ homeUser "@staff" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # system.primaryUser for activation scripts that need user context
  system.primaryUser = homeUser;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "right";
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  system.defaults.NSGlobalDomain.InitialKeyRepeat = 12;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;

  # macOS per-domain DNS resolver：仅 *.soraliu.dev 走本地 dnsmasq (port 5353)
  environment.etc."resolver/soraliu.dev".text = ''
    nameserver 127.0.0.1
    port 5353
  '';

  fonts.packages = with unstablePkgs; [
    nerd-fonts.sauce-code-pro
  ];
}
