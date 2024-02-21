{ config, pkgs, lib, ... }: {
  home.username = "root";
  home.homeDirectory = "/root";

  home.packages = with pkgs; [
    # hello
  ];
}
