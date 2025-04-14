{ pkgs, ... }: {
  imports = [
    ../pkgs/sops
    ../pkgs/pm2

    ./modules/home-manager
    ./modules/network/hysteria
    ./modules/network/frp
  ];

  home.packages = with pkgs; [ ];
}
