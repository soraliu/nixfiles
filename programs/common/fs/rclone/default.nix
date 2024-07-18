{ pkgs, unstablePkgs, lib, config, ... }:
let
  pathToRcloneRoot = "${builtins.getEnv "HOME"}/Rclone/";

  cfg = config.programs.rclone;
  # [{ remote = "gdrive:path/to/dir"; local = "$HOME/Drive/path/to/dir"; link = "/another_path/to/dir"; filter = "/path/to/filters.txt";  }]
  syncPaths = map ({remote, local ? "", filter ? "", command ? "bisync"}: {
    inherit remote filter command;
    link = local;
    local = pathToRcloneRoot + (builtins.elemAt (lib.strings.splitString ":" remote) 1);
  }) cfg.syncPaths;
  commonFilter = pkgs.writeText "rclone-filters.txt" ''
# NOTICE: If you make changes to this file you MUST do a --resync run.
- .DS_Store
- .git
- node_modules
  '';
  pathToScript = pkgs.writeText "rclone-pm2-script" ''
    #!/usr/bin/env zsh

    ${if builtins.length syncPaths == 0 then "echo 'Nothing to sync!'" else ""}

    ${builtins.concatStringsSep "\n\n" (map ({local, remote, filter, command, ...}: "
      (
        if [ '${command}' = 'copy' ]; then
          echo 'copying ${remote} to ${local}...'
          ${unstablePkgs.rclone}/bin/rclone copy '${remote}' '${local}' --filter-from '${commonFilter}' ${if filter != "" then "--filter-from '" + filter + "'" else ""} -v
        elif [ '${command}' = 'sync' ]; then
          echo 'bisyncing ${remote} to ${local}...'
          ${unstablePkgs.rclone}/bin/rclone bisync '${remote}' '${local}' --filter-from '${commonFilter}' ${if filter != "" then "--filter-from '" + filter + "'" else ""} --remove-empty-dirs --fix-case --resilient --conflict-resolve newer -v || \
          ${unstablePkgs.rclone}/bin/rclone bisync '${remote}' '${local}' --filter-from '${commonFilter}' ${if filter != "" then "--filter-from '" + filter + "'" else ""} --remove-empty-dirs --fix-case --resilient --conflict-resolve newer --resync --resync-mode newer -v
        else
          echo 'invalid command ${command}!'
        fi
      ) &
    ") syncPaths)}

    wait

    echo "countdown started for 30 seconds..."
    for ((i=30; i>=0; i--))
    do
        echo "Time left: $i seconds"
        sleep 1
    done
    echo "Countdown completed."

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
      example = [{ local = "/path/to/dir"; remote = "gdrive:path/to/dir"; filter = "/path/to/filters.txt"; command = "copy"; }];
      description = lib.mdDoc "rclone [command] paths. Notice: paths only support directories and can't be ended with /";
    };
  };

  config = with lib; mkIf cfg.enable {
    home = {
      packages = [ unstablePkgs.rclone ];

      activation.initRclone = hm.dag.entryAfter ["linkGeneration"] ''
        path_to_rclone_conf=$HOME/.config/rclone/rclone.conf
        path_to_rclone_bin=${unstablePkgs.rclone}/bin/rclone

        cp "$path_to_rclone_conf".readonly "$path_to_rclone_conf"
        chmod +w "$path_to_rclone_conf"

        ${builtins.concatStringsSep "\n\n" (map ({remote, local, link, filter, ...}: "(
          # check if the dir of local exists
          mkdir -p $(dirname '${local}')

          # backup link dir, and relink
          # if link exists but local doesn't, copy link to local
          if [ '${link}' != '' ]; then
            [ -L '${link}' ] && unlink '${link}'
            [ -e '${link}' ] && [ ! -e '${local}' ] && cp -r '${link}' '${local}'
            [ -e '${link}' ] && mv -f '${link}' '${link}.backup'
            ln -s '${local}' '${link}'
          fi

          # check if remote exists
          [ -d '${local}' ] && $path_to_rclone_bin mkdir '${remote}' || echo '${remote} exists!'

          # check if local dir exists
          if [ ! -d '${local}' ]; then
            mkdir -p '${local}'
          fi
        ) &") syncPaths)}

        wait
      '';
    };

    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/rclone/rclone.enc.conf";
          to = ".config/rclone/rclone.conf.readonly";
        }];
      };
      pm2 = lib.mkIf (builtins.length syncPaths > 0) {
        services = [{
          name = "rclone";
          script = pathToScript;
          interpreter = "${pkgs.zsh}/bin/zsh";
        }];
      };
    };
  };

}
