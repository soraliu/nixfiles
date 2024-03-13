{ config, pkgs, ... }: {
  imports = [
    # base pkgs
    ./base

    # home-manager self
    ./home-manager

    # version control
    ./git

    # encrypt & decrypt
    ./sops

    # search
    ./fzf
    ./ripgrep

    # editor
    ./neovim

    # shell
    ./zsh
    ./shell-gpt
    ./pet
    ./zellij
  ];
}
