{ pkgs, ... }: {
  imports = [
    ./base.nix

    ./modules/network/hysteria
  ];

  home.packages = with pkgs; [ ];
}
