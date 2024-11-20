{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    python3
    python311Packages.pip
  ];
}
