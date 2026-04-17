{ config, lib, pkgs, homeUser, ... }: 
let
  versions = import ../versions.nix;
in
{
  imports = [
    ../pkgs/sops
  ];

  # 注: experimental-features / trusted-users 已迁到 pkgs/determinate 的 customSettings
  # determinateNix.enable = true 会自动设置 nix.enable = false, nix.settings.* 不再起作用


  environment.shells = [ pkgs.zsh ];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # homeUser 主组设为 wheel，获得 sudo 权限 (NixOS 25.11 要求显式设置 group)
  users.users.${homeUser} = {
    isNormalUser = true;
    group = "wheel";
  };

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
