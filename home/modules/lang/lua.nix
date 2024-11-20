{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    stylua
  ];
}
