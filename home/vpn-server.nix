{ pkgs, ... }: {
  imports = [
    ../pkgs/sops
    ../pkgs/pm2

    ./modules/home-manager
    ./modules/network/hysteria
    ./modules/network/frp
    ./modules/network/nginx
  ];

  home.packages = with pkgs; [
    bandwhich
    iperf3
  ];
}
