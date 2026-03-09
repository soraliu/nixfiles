{ pkgs, ... }: {
  imports = [
    ../core/base.nix
    
    ../modules/network/frp
    ../modules/network/nginx/drive-server.nix
  ];

  home.packages = with pkgs; [ ];
}
