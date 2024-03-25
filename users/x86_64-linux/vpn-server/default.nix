{ pkgs, ... }: {
  home.username = "root";
  home.homeDirectory = "/root";

  imports = [
    ./hysteria
  ];

  home.packages = with pkgs; [ ];
}
