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
    cmd_exe="${config.wsl.wslConf.automount.root}/c/Windows/System32/cmd.exe"
    if [ -x "$cmd_exe" ]; then
      WIN_PROFILE=$($cmd_exe /C "echo %USERPROFILE%" 2>/dev/null)
      WIN_PROFILE=''${WIN_PROFILE//$'\r'/}
      WIN_PROFILE=''${WIN_PROFILE//$'\n'/}
      if [ -n "$WIN_PROFILE" ]; then
        if [ -x /bin/wslpath ]; then
          WIN_PROFILE_WSL=$(/bin/wslpath "$WIN_PROFILE")
        else
          WIN_DRIVE=''${WIN_PROFILE%%:*}
          WIN_DRIVE=''${WIN_DRIVE,,}
          WIN_REST=''${WIN_PROFILE#?:}
          WIN_REST=''${WIN_REST//\\//}
          WIN_PROFILE_WSL="${config.wsl.wslConf.automount.root}/$WIN_DRIVE$WIN_REST"
        fi
        WSLCONFIG_PATH="$WIN_PROFILE_WSL/.wslconfig"
        cat > "$WSLCONFIG_PATH" << 'EOF'
[wsl2]
networkingMode=mirrored
firewall=false

[experimental]
hostAddressLoopback=true
EOF
      fi
    else
      echo "cmd.exe not found at $cmd_exe, skipping .wslconfig sync"
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
}
