# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, nixos-wsl, homeUser, ... }:

{
  imports = [
    ./nixos.nix
  ];

  wsl.enable = true;
  wsl.wslConf.boot.systemd = true;
  wsl.wslConf.user.default = lib.mkForce homeUser;

  # Sync .wslconfig to Windows side on activation
  system.activationScripts.wslconfig.text = ''
    export PATH=$PATH:/run/wrappers/bin:/run/current-system/sw/bin:/mnt/c/Windows/System32
    if command -v wslpath >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
      WIN_PROFILE=$(cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
      if [ -n "$WIN_PROFILE" ]; then
        WSLCONFIG_PATH="$(wslpath "$WIN_PROFILE")/.wslconfig"
        cat > "$WSLCONFIG_PATH" << 'EOF'
[wsl2]
networkingMode=mirrored
firewall=false

[experimental]
hostAddressLoopback=true
EOF
      fi
    else
      echo "wslpath or cmd.exe not found, skipping .wslconfig sync"
    fi
  '';

  # docker support
  # TL;DR: https://github.com/nix-community/NixOS-WSL/issues/235
  wsl.extraBin = with pkgs; [
    { src = "${uutils-coreutils-noprefix}/bin/cat"; }
    { src = "${uutils-coreutils-noprefix}/bin/whoami"; }
    { src = "${busybox}/bin/addgroup"; }
    { src = "${su}/bin/groupadd"; }
  ];


  # fileSystems."/mnt/nas" = {
  #   device = "//192.168.31.3/personal_folder";
  #   fsType = "cifs";
  #   options = [ "credentials=/etc/.smbcredentials,file_mode=0777,dir_mode=0777" ];
  # };

  # programs.sops = {
  #   decryptFiles = [{
  #     from = "secrets/etc/.smbcredentials.enc";
  #     to = ".smbcredentials";
  #   }];
  # };
}
