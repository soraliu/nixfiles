{ config, lib, pkgs, ... }:
let
  home = builtins.getEnv "HOME";
in
with lib; {
  options.clean = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Whether to set up a minimal configuration that will remove all managed
      files and packages.
    '';
  };

  config = mkIf config.clean {
    home.username = builtins.getEnv "USER";
    home.homeDirectory = builtins.getEnv "HOME";

    home.packages = lib.mkForce [ ];
    home.file = lib.mkForce { };
    home.stateVersion = lib.mkForce "23.11";
    home.enableNixpkgsReleaseCheck = lib.mkForce false;
    manual.manpages.enable = lib.mkForce false;
    news.display = lib.mkForce "silent";

    home.activation.clean =
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        set +e

        pm2_bin=${pkgs.pm2}/bin/pm2
        $pm2_bin delete all 2>/dev/null
        $pm2_bin save --force

        # Remove rclone files
        echo "rm -rf ${home}/Rclone"
        rm -rf ${home}/Rclone
        echo "rm -rf ${home}/.config/rclone"
        rm -rf ${home}/.config/rclone

        set -e
      '';
  };
}
