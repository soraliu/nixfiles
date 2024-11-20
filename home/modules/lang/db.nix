{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    sqlite
  ];
}
