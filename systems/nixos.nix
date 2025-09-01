{ config, lib, pkgs, ... }: 
let
  versions = import ../versions.nix;
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  environment.shells = [ pkgs.zsh ];
  users.defaultUserShell = pkgs.zsh;
  users.users.nixos.ignoreShellProgramCheck = true;
  users.users.root.ignoreShellProgramCheck = true;


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = versions.version; # Did you read the comment?
  time.timeZone = "Asia/Shanghai";
}
