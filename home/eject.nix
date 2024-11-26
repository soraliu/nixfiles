{ config, lib, pkgs, ... }:
let
  home = builtins.getEnv "HOME";
in
with lib; {
  options.eject = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Whether to set up a minimal configuration that will remove all managed
      files and packages.
    '';
  };

  config = mkIf config.eject {
    home.username = builtins.getEnv "USER";
    home.homeDirectory = home;

    home.packages = lib.mkForce [ ];
    home.file = lib.mkForce { };
    home.stateVersion = lib.mkForce "23.11";
    home.enableNixpkgsReleaseCheck = lib.mkForce false;
    manual.manpages.enable = lib.mkForce false;
    news.display = lib.mkForce "silent";

    home.activation.eject =
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        set +e

        # delete all pm2 services
        pm2_bin=${pkgs.pm2}/bin/pm2
        $pm2_bin delete all 2>/dev/null
        $pm2_bin save --force

        # Remove rclone files
        echo "rm -rf ${home}/Rclone"
        rm -rf ${home}/Rclone
        echo "rm -rf ${home}/.config/rclone"
        rm -rf ${home}/.config/rclone

        # Delete pet files
        echo "rm -rf ${home}/.config/pet"
        rm -rf ${home}/.config/pet

        # Delete shell_gpt files
        echo "rm -rf ${home}/.config/shell_gpt"
        rm -rf ${home}/.config/shell_gpt

        set -e
      '';
  };
}
