{ pkgs, lib, config, useSecret ? false, ... }: let
  cfg = config.programs.sops;
  decryptFiles = cfg.decryptFiles;
  decryptedPath = pkgs.callPackage ./decrypt.nix {
    inherit pkgs;
    ageKeyFile = "${config.home.homeDirectory}/.age/keys.txt";
    files = decryptFiles;
  };
in {
  options.programs.sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = useSecret;
      example = false;
      description = lib.mdDoc "Whether to enable sops.";
    };
    decryptFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      example = [{from = "secrets/.git-credentials.enc"; to = ".git-credentials";}];
      description = lib.mdDoc "The files that need to be decrypt. `to` is related to $HOME";
    };
  };

  config.home = with lib; mkIf cfg.enable {
    packages = with pkgs; [
      age
      sops
    ];
    sessionVariables = {
      SOPS_AGE_KEY_FILE = "$HOME/.age/keys.txt";
    };
    file = foldl' (acc: elem: acc // {"${elem.to}".source = "${decryptedPath}/${elem.to}";}) {} decryptFiles;
  };
}
