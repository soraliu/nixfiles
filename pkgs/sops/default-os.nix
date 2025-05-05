{ pkgs, lib, config, ... }:
let
  cfg = config.programs.sops;
  decryptFiles = cfg.decryptFiles;
  decryptedPath = pkgs.callPackage ./decrypt.nix {
    inherit pkgs;
    files = decryptFiles;
  };
in
{
  options.programs.sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable sops.";
    };
    decryptFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = [{ from = "secrets/.git-credentials.enc"; to = ".git-credentials"; }];
      description = lib.mdDoc "The files that need to be decrypt. `to` is related to $HOME";
    };
  };

  config = with lib; mkIf (cfg.enable && (length decryptFiles > 0)) {
    environment.etc = (foldl' (acc: elem: acc // { "${elem.to}".source = "${decryptedPath}/${elem.to}"; }) { } decryptFiles);
  };
}
