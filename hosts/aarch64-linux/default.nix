{ config, lib, pkgs, ... }: let
  font = with pkgs; import ../common/font.nix { inherit fetchurl; };
in

{
  # Simply install just the packages
  environment.packages = with pkgs; [];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "23.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  #time.timeZone = "Europe/Cerlin";

  terminal.font = font.medium;
}
