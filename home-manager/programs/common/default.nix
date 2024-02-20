{ config, pkgs, ... }: {
  imports = [
    ./home-manager.nix
    ./neovim
    ./git.nix
  ];
}
