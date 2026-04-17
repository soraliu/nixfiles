{ config, lib, system, homeUser, ... }: 
let
  versions = import ../../../versions.nix;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports = [
    ../sys/nix-hygiene
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = versions.version;
  home.username = lib.mkDefault homeUser;
  home.homeDirectory = lib.mkDefault (
    if homeUser == "root" then "/root"
    else if isDarwin then "/Users/${homeUser}"
    else "/home/${homeUser}"
  );

  home.sessionVariables = {
    HOME_PROFILE_DIRECTORY = config.home.profileDirectory;
  };
}
