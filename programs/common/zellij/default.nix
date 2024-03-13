{ pkgs, lib, config, ... }: {
  programs = {
    zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home = {
    file = {
      ".config/zellij/config.kdl".source = ./config.kdl;
    };
    sessionVariables = {
      ZELLIJ_CONFIG_DIR = "$HOME/.config/zellij";
    };
  };
}
