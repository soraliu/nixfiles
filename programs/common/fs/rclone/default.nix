{ pkgs, unstablePkgs, lib, config, ... }:
let
  cfg = config.programs.rclone;
  # [{ remote = "gdrive:path/to/dir"; local = "~/Drive/path/to/dir"; link = "/another_path/to/dir"; filter = "/path/to/filters.txt";  }]
  paths = map ({local, remote, filter}: {
    inherit remote filter;
    link = local;
    local = builtins.getEnv "HOME" + "/Drive/" + (builtins.elemAt (lib.strings.splitString ":" remote) 1);
  }) cfg.syncPaths;
  pathToScript = pkgs.writeText "rclone-pm2-script" ''
    #!/usr/bin/env zsh

    ${if builtins.length paths == 0 then "echo 'Nothing to sync!'" else ""}
    ${builtins.concatStringsSep "\n\n" (map ({local, remote, filter, ...}: "${unstablePkgs.rclone}/bin/rclone bisync '${local}' '${remote}' --filter-from '${filter}' --create-empty-src-dirs --slow-hash-sync-only --fix-case --resilient -v &") paths)}

    wait
  '';
in
{
  imports = [
    ../sops
    ../../process/pm2
  ];

  options.programs.rclone = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable rclone.";
    };
    syncPaths = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = [{ local = "/path/to/dir"; remote = "gdrive:path/to/dir"; filter = "/path/to/filters.txt"; }];
      description = lib.mdDoc "rclone bisync paths";
    };
  };

  config = with lib; mkIf cfg.enable {
    home = {
      packages = [ unstablePkgs.rclone ];

      activation.initRclone = hm.dag.entryAfter ["linkGeneration"] ''
        path_to_rclone_conf=$HOME/.config/rclone/rclone.conf

        cp "$path_to_rclone_conf".readonly "$path_to_rclone_conf"
        chmod +w "$path_to_rclone_conf"

        ${builtins.concatStringsSep "\n\n" (map ({remote, local, link, filter}: "\
          [ ! -e '${local}' ] && ${unstablePkgs.rclone}/bin/rclone bisync '${local}' '${remote}' --filter-from '${filter}' --create-empty-src-dirs --slow-hash-sync-only --fix-case --resilient --resync; \
          [ -L '${link}' ] && unlink '${link}' \
          [ -e '${link}' ] && mv -f '${link}' '${link}.backup' \
          ln -s '${local}' '${link}'; \
        ") paths)}
      '';
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/rclone/rclone.enc.conf";
          to = ".config/rclone/rclone.conf.readonly";
        }];
      };
      pm2 = {
        services = [{
          name = "rclone";
          script = pathToScript;
          interpreter = "${pkgs.zsh}/bin/zsh";
          autorestart = false;
          cron_restart = "*/1 * * * *";
        }];
      };
    };
  };

}
