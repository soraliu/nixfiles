{ pkgs, config, ... }: {
  imports = [
    ../../pkgs/sops
    ../../pkgs/pm2
    ../modules/home-manager
    ../modules/sys/network

    ../modules/network/hysteria
    ../modules/network/caddy/relayer.nix # Caddy 反代（Let's Encrypt）
    ../modules/network/caddy-cloudflare # Cloudflare DNS 同步
    ../modules/network/nebula
  ];

  programs.bash.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.volta/bin"
    "$GOPATH/bin"
  ];
}
