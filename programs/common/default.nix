{ config, pkgs, ... }: {
  imports = [
    # base pkgs
    ./base.nix

    # home-manager self
    ./home-manager.nix

    # version control
    ./git.nix

    # encrypt & decrypt
    ./gpg.nix
    # ./sops.nix

    # search
    ./fzf.nix
    ./ripgrep.nix

    # editor
    ./neovim

    # shell
    ./zsh
  ];
}
