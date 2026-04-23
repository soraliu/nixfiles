{ config, ... }:
{
  programs.sshd-authorize.keyDir = lib.mkForce "${config.home.homeDirectory}/.ssh";
}
