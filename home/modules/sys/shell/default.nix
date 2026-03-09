{ pkgs, ... }:

{
  home.packages = with pkgs; [
    comma # run software without installing it (need nix-index), Github: https://github.com/nix-community/comma
  ];
}
