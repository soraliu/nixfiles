{ config, pkgs, ... }: {
  imports = [
    ./home-manager.nix
    ./bash.nix
    ./gpg.nix
    ./sops.nix
    ./git.nix

    ./neovim
  ];
}
