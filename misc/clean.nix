{ config, lib, pkgs, ... }: with lib; {
  options.clean = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to set up a minimal configuration that will remove all managed
      files and packages.
    '';
  };

  config = mkIf config.clean {
    home.packages = lib.mkForce [ ];
    home.file = lib.mkForce { };
    home.stateVersion = lib.mkForce "23.11";
    home.enableNixpkgsReleaseCheck = lib.mkForce false;
    manual.manpages.enable = lib.mkForce false;
    news.display = lib.mkForce "silent";

    home.activation.clean =
      lib.hm.dag.entryAfter [ "installPackages" "linkGeneration" ] ''
        # Remove rclone files
        rm -rf $HOME/Rclone
      '';
  };
}
