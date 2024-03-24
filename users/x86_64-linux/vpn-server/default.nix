{ pkgs, ... }: {
  home.username = "root";
  home.homeDirectory = "/root";

  imports = [
    ./sing-box
  ];

  home.packages = with pkgs; [ ];
}
