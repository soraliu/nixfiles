{ pkgs, ... }: {
  imports = [
    ../core/base.nix
    
    ../modules/sys/network

    ../modules/network/hysteria
    ../modules/network/frp
    ../modules/network/nginx
  ];

  programs.bash.enable = true;

  home.packages = with pkgs; [
    iperf3
  ];

  home.sessionPath = [
    "$HOME/.volta/bin"
    "$GOPATH/bin"
  ];
}
