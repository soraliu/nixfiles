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

  # macOS per-domain DNS resolver：仅 *.soraliu.dev 走本地 dnsmasq
  environment.etc."resolver/soraliu.dev".text = ''
    nameserver 127.0.0.1
  '';

  # dnsmasq 以 root 运行才能绑定 53 端口
  launchd.daemons.dnsmasq = {
    serviceConfig = {
      Label = "dev.soraliu.dnsmasq";
      ProgramArguments = [
        "${pkgs.dnsmasq}/bin/dnsmasq"
        "--keep-in-foreground"
        "-C"
        "/Users/${homeUser}/.config/dnsmasq/dnsmasq.conf"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/dnsmasq.log";
      StandardErrorPath = "/tmp/dnsmasq.err.log";
    };
  };

  fonts.packages = with unstablePkgs; [
    nerd-fonts.sauce-code-pro
  ];
}
