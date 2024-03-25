{ pkgs, ... }: {
  imports = [
    ./raycast
    ./hiddify
  ];

  home.packages = with pkgs; [ ];

  home.sessionVariables = { };
}
