{ pkgs, config, ... }: {
  imports = [
    ../core/base.nix

    ../modules/sys/network

    ../modules/network/caddy/relayer.nix # Caddy 反代（Let's Encrypt）
    ../modules/network/caddy-cloudflare # Cloudflare DNS 同步
    ../modules/network/nebula
  ];

  programs.bash.enable = true;

  home.packages = with pkgs; [ ];

  home.sessionPath = [
    "${config.home.homeDirectory}/.volta/bin"
    "$GOPATH/bin"
  ];
}
