{ config, ... }: 
let
  versions = import ../../../versions.nix;
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = versions.version;
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.sessionVariables = {
    HOME_PROFILE_DIRECTORY = config.home.profileDirectory;
  };
}
