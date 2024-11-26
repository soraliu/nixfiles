{ pkgs, ... }: {
  imports = [
    ../pkgs/sops
    ../pkgs/pm2

    ./modules/home-manager
    ./modules/network/hysteria
  ];

  home.packages = with pkgs; [ ];
}
