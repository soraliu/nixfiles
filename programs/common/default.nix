{ config, pkgs, ... }: {
  imports = [
    ./home-manager.nix
    ./git.nix
    ./gpg.nix

    ./neovim
  ];
}
