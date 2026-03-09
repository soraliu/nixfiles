{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tldr # community-maintained help pages, Github: https://github.com/tldr-pages/tldr
  ];
}
