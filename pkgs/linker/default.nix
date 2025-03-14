{ pkgs, unstablePkgs, lib, config, useMirrorDrive, ... }:
let
  pathToHome = config.home.homeDirectory;
  cfg = config.programs.linker;
  links = cfg.links;
in
{
  options.programs.linker = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable linker.";
    };
    useMirror = lib.mkOption {
      type = lib.types.bool;
      default = useMirrorDrive;
      example = true;
      description = lib.mdDoc "Whether to use rclone to copy files to lcoal.";
    };
    links = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = [{ source = "gdrive:path/to/source/file_or_dir"; link = "/path/to/link/file_or_dir"; }];
      description = lib.mdDoc "Link paths to dirs in remote storage. Support Google Drive or local absolute path";
    };
  };

  config = with lib; mkIf (cfg.enable && (length links > 0)) (mkMerge [
    (mkIf (!cfg.useMirror) {
      home.packages = [ pkgs.gnused ];
      home.activation.initLinker = hm.dag.entryAfter [ "linkGeneration" ] ''
        ${builtins.concatStringsSep "\n\n" (map ({source, link}: "
          # check if the link isn't a symlink and has already existed
          [ -L '${link}' ] && unlink '${link}'
          [ -e '${link}' ] && mv -f '${link}' '${link}.backup'

          mkdir -p $(dirname '${link}')

          path_to_source=${pathToHome}/$(echo '${source}' | ${pkgs.gnused}/bin/sed 's/gdrive:/Google Drive\\/My Drive\\//')
          ln -s \"$path_to_source\" '${link}'
          echo \"${link} => $path_to_source\"

        ") links)}
      '';
    })
    (mkIf cfg.useMirror {
      programs.rclone.syncPaths = builtins.map
        ({ source, link }: {
          remote = source;
          local = link;
          command = "copy";
        })
        links;
    })
  ]);
}
