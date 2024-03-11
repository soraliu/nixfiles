# decrypt these files, like: [{
#   "from":"secrets/.git-credentials.enc",
#   "to":".git-credentials"
# }]
# and save those decrypted files under `/nix/store/${hash}-sops-decrypted-files/`
# e.g.: `/nix/store/xz45jvrijbicfqv8rvc3nqxgn5zakj20-sops-decrypted-files/.git-credentials`
# files.[].from -> related to `root` path
# files.[].to -> related to `home` path
{ pkgs ? import <nixpkgs> { }, files ? [] }: let 
  ageKeyFile = ~/.age/keys.txt;
in
pkgs.stdenv.mkDerivation {
  name = "sops-decrypted-files";
  version = "0.0.1";
  system = builtins.currentSystem;

  src = ../../..;

  buildInputs = with pkgs; [ age sops ];

  buildPhase = ''
    #!${pkgs.runtimeShell}
    mkdir -p $out

    export SOPS_AGE_KEY_FILE=${ageKeyFile}

    decryptSopsFile() {
      encrypted_file="$1"
      path_to_decrypted_file="$out/$2"

      # ensure that directory exists
      mkdir -p "$(basename $path_to_decrypted_file)"

      echo "$encrypted_file -> $path_to_decrypted_file"

      ${pkgs.sops}/bin/sops --decrypt "$encrypted_file" > "$path_to_decrypted_file"

      echo "$encrypted_file -> $path_to_decrypted_file"
    }

    echo "🟡🟡🟡 Start to decrypt files..."

    ${builtins.concatStringsSep "\n\n" (map ({from, to}: "decryptSopsFile $src/${from} ${to}") files)}
  '';

  installPhase = ''
    echo "🎉🎉🎉 Finish decrypting!"
  '';
}
