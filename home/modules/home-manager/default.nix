{ config, lib, ... }: 
let
  versions = import ../../../versions.nix;
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = versions.version;
  home.username = lib.mkDefault (builtins.getEnv "USER");
  home.homeDirectory = lib.mkDefault (builtins.getEnv "HOME");

  home.sessionVariables = {
    HOME_PROFILE_DIRECTORY = config.home.profileDirectory;
  };
}
