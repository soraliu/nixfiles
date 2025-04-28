{ pkgs, ... }: {
  imports = [
    ../pkgs/sops
    ../pkgs/pm2

    ./modules/home-manager
    ./modules/network/frp
    ./modules/network/nginx/drive-server.nix
  ];

  home.packages = with pkgs; [ ];
}
