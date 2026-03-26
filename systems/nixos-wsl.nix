# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, nixos-wsl, homeUser, ... }:

{
  imports = [
    ./nixos-wsl-base.nix
  ];

  # 解决 extra-sandbox-paths 的权限问题, 是个鸡蛋问题, 必须先执行 nixos-wsl-base 声明当前用户为 trusted user, 然后才能访问 /tmp/.age
  fileSystems."/mnt/nas" = {
    device = "//192.168.31.3/personal_folder";
    fsType = "cifs";
    options = [ "credentials=/etc/.smbcredentials,file_mode=0777,dir_mode=0777" ];
  };

  programs.sops = {
    decryptFiles = [{
      from = "secrets/etc/.smbcredentials.enc";
      to = ".smbcredentials";
    }];
  };
}
