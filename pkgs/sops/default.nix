{ pkgs, lib, config, options, useSecret ? true, ... }:
let
  cfg = config.programs.sops;
  decryptFiles = cfg.decryptFiles;
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
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = [{ from = "secrets/.git-credentials.enc"; to = ".git-credentials"; }];
      description = lib.mdDoc "The files that need to be decrypt. `to` is related to $HOME or /etc depending on environment";
    };
  };

  config = lib.mkIf (cfg.enable && (builtins.length decryptFiles > 0)) (
    if isHM then {
      home.packages = with pkgs; [ age sops ];
      home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "/tmp/.age/keys.txt";
      };
      home.file = lib.foldl' (acc: elem: acc // { "${elem.to}".source = "${decryptedPath}/${elem.to}"; }) { } decryptFiles;
    } else {
      environment.systemPackages = with pkgs; [ age sops ];
      environment.variables = {
        SOPS_AGE_KEY_FILE = "/tmp/.age/keys.txt";
      };
      environment.etc = lib.foldl' (acc: elem: acc // { "${elem.to}".source = "${decryptedPath}/${elem.to}"; }) { } decryptFiles;
    }
  );
}
