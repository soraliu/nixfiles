{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    gcc
  ];
}
