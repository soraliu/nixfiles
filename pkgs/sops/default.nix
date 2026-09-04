{ pkgs, lib, config, options, useSecret ? true, ... }:
let
  cfg = config.programs.sops;
  decryptFiles = cfg.decryptFiles;
  modeFiles = lib.filter (file: file.mode != null) decryptFiles;
  decryptedPath = pkgs.callPackage ./decrypt.nix {
    inherit pkgs;
    files = decryptFiles;
  };
  
  isHM = options ? home;
in
{
  options.programs.sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = useSecret;
      example = false;
      description = lib.mdDoc "Whether to enable sops.";
    };
    decryptFiles = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          from = lib.mkOption {
            type = lib.types.str;
            description = "相对于仓库根目录的加密文件路径";
          };
          to = lib.mkOption {
            type = lib.types.str;
            description = "相对于用户主目录或 /etc 的解密目标路径";
          };
          mode = lib.mkOption {
            type = lib.types.nullOr (lib.types.strMatching "[0-7]{4}");
            default = null;
            example = "0600";
            description = "解密目标文件的 Unix 权限；未设置时保持符号链接";
          };
        };
      });
      default = [ ];
      example = [{
        from = "secrets/.git-credentials.enc";
        to = ".git-credentials";
        mode = "0600";
      }];
      description = lib.mdDoc "The files that need to be decrypt. `to` is related to $HOME or /etc depending on environment";
    };
  };

  config = lib.mkIf (cfg.enable && (builtins.length decryptFiles > 0)) (
    if isHM then {
      home.packages = with pkgs; [ age sops ];
      home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "/tmp/.age/keys.txt";
      };
      home.file = lib.foldl' (acc: elem: acc // {
        "${elem.to}" = {
          source = "${decryptedPath}/${elem.to}";
        } // lib.optionalAttrs (elem.mode != null) {
          force = true;
        };
      }) { } decryptFiles;
      home.activation.sopsFileModes = lib.mkIf (builtins.length modeFiles > 0) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.concatMapStringsSep "\n" (elem: ''
            run ${pkgs.coreutils}/bin/install -D -m ${lib.escapeShellArg elem.mode} \
              ${lib.escapeShellArg "${decryptedPath}/${elem.to}"} \
              ${lib.escapeShellArg "${config.home.homeDirectory}/${elem.to}"}
          '') modeFiles
        )
      );
    } else {
      environment.systemPackages = with pkgs; [ age sops ];
      environment.variables = {
        SOPS_AGE_KEY_FILE = "/tmp/.age/keys.txt";
      };
      environment.etc = lib.foldl' (acc: elem: acc // {
        "${elem.to}" = {
          source = "${decryptedPath}/${elem.to}";
        } // lib.optionalAttrs (elem.mode != null) {
          inherit (elem) mode;
        };
      }) { } decryptFiles;
    }
  );
}
