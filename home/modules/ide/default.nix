{ ... }: {
  imports = [
    ./git
    ./zsh
    ./neovim
    ./zellij
    ./search

    ./copilot.nix
    ./iac.nix
  ];
}
