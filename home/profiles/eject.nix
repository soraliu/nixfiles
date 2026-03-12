{ config, lib, pkgs, system, homeUser, ... }:
let
  versions = import ../../versions.nix;
  isDarwin = builtins.match ".*-darwin" system != null;
  homeDir = config.home.homeDirectory;
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
    home.username = homeUser;
    home.homeDirectory =
      if homeUser == "root" then "/root"
      else if isDarwin then "/Users/${homeUser}"
      else "/home/${homeUser}";

    home.packages = lib.mkForce [ ];
    home.file = lib.mkForce { };
    home.stateVersion = lib.mkForce versions.version;
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
        echo "rm -rf ${homeDir}/Rclone"
        rm -rf ${homeDir}/Rclone
        echo "rm -rf ${homeDir}/.config/rclone"
        rm -rf ${homeDir}/.config/rclone

        # Delete pet files
        echo "rm -rf ${homeDir}/.config/pet"
        rm -rf ${homeDir}/.config/pet

        # Delete shell_gpt files
        echo "rm -rf ${homeDir}/.config/shell_gpt"
        rm -rf ${homeDir}/.config/shell_gpt

        set -e
      '';
  };
}
