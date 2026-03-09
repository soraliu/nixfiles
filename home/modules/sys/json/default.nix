{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jq # jq format
    gojq # high-performance jq alternative in Go, Github: https://github.com/itchyny/gojq
  ];
}
