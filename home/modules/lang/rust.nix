{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    rustc
    cargo
  ];
}
