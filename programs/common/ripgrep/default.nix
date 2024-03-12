{ pkgs, lib, config, ... }: {
  config.programs.ripgrep = {
    enable = true;
  };
}
