{ config, pkgs, lib, ... }: let
  cfg = config.programs.sops;
  files = with lib; map ({from, to}: {inherit from to; placeholder = pkgs.writeText (baseNameOf to) "";}) cfg.decryptFiles;
in {
  options.programs.sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable sops.";
    };
    decryptFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      example = [{from = "secrets/.git-credentials.enc"; to = "$HOME/.git-credentials";}];
      description = lib.mdDoc "The files that need to be decrypt";
    };
  };

  config.home = with lib; mkIf cfg.enable {
    packages = with pkgs; [
      sops
    ];
    file = foldl' (acc: elem: acc // {"${elem.to}".source = elem.placeholder;}) {} files;
    activation.decryptSopsFiles = let
      scriptPath = "${pkgs.writeScript "decrypt-sops-files.sh" ''
        #!${pkgs.runtimeShell}

        encrypted_file="$1"

        target_dir_or_file="$2"
        if [ -z "$target_dir_or_file" ]; then
          target_dir_or_file=$(dirname "$encrypted_file")
        fi

        target_file="$target_dir_or_file"
        if [ -d "$target_file" ]; then
          target_file="$target_dir_or_file/$(basename "$encrypted_file" .enc)"
        fi

        # ensure that directory exists
        mkdir -p "$(basename $target_file)"

        ${pkgs.sops}/bin/sops --decrypt "$encrypted_file" > "$target_file"

        echo "$encrypted_file -> $target_file"
      ''}";
    in builtins.trace "Inspecting attrs: ${builtins.toJSON files}" lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "🟡🟡🟡 Start to decrypt files..."

      project_root_dir="${builtins.toPath ../..}"

      export GPG_TTY=$(tty)
      export SOPS_GPG_EXEC=${pkgs.gnupg}/bin/gpg

      ${concatStringsSep "\n\n" (map ({from, to, placeholder}: "${scriptPath} $project_root_dir/${from} ${placeholder}") files)}

      echo "🎉🎉🎉 Finish decrypting!"
    '';
  };
}
