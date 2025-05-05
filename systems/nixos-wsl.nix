# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, nixos-wsl, ... }:

{
  imports = [
    ./nixos.nix
    ../pkgs/sops/default-os.nix
  ];

  wsl.enable = true;
  # wsl.defaultUser = "root";

  # docker support
  # TL;DR: https://github.com/nix-community/NixOS-WSL/issues/235
  wsl.extraBin = with pkgs; [
    { src = "${uutils-coreutils-noprefix}/bin/cat"; }
    { src = "${uutils-coreutils-noprefix}/bin/whoami"; }
    { src = "${busybox}/bin/addgroup"; }
    { src = "${su}/bin/groupadd"; }
  ];


  # //192.168.31.133/personal_folder /mnt/nas cifs username=soraliu,password=Q9kEtg1h1@HGjo,iocharset=utf8,vers=3.0,uid=1000,gid=1000,dir_mode=0777,file_mode=0777,sec=ntlmssp 0 0
  fileSystems."/mnt/nas" = {
    device = "//192.168.31.133/personal_folder";
    fsType = "cifs";
    options = [ "credentials=/etc/.smbcredentials" ];
  };

  programs.sops = {
    decryptFiles = [{
      from = "secrets/etc/.smbcredentials.enc";
      to = ".smbcredentials";
    }];
  };
}
