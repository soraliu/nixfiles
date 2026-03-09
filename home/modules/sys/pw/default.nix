{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli # Bitwarden CLI
  ];
}
