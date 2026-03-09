{ pkgs, ... }:

{
  home.packages = with pkgs; [
    docker-client # docker cli
  ];
}
