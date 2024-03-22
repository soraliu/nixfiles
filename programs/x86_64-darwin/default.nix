{ config, pkgs, ... }: {
  imports = [
    ./raycast
  ];

  home.packages = with pkgs; [ ];

  home.sessionVariables = { };
}
