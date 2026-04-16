{ pkgs, config, ... }: {
  imports = [
    ../../pkgs/sops
    ../../pkgs/pm2
    ../modules/home-manager
    ../modules/sys/network

    ../modules/network/hysteria
  ];

  programs.bash.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.volta/bin"
    "$GOPATH/bin"
  ];
}
