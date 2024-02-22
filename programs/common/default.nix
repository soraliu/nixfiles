{ config, pkgs, ... }: {
  imports = [
    ./home-manager.nix

    # shell
    ./bash.nix

    # version control
    ./git.nix

    # encrypt & decrypt
    ./sops.nix

    # search
    ./fzf.nix
    ./ripgrep.nix

    # editor
    ./neovim
  ];
}
