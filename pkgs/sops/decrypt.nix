# decrypt these files, like: [{
#   "from":"secrets/.git-credentials.enc",
#   "to":".git-credentials"
# }]
# and save those decrypted files under `/nix/store/${hash}-sops-decrypted-files/`
# e.g.: `/nix/store/xz45jvrijbicfqv8rvc3nqxgn5zakj20-sops-decrypted-files/.git-credentials`
# files.[].from -> related to `root` path
# files.[].to -> related to `home` path
{ pkgs, ageKeyFile ? "/tmp/.age/keys.txt", files ? [] }: pkgs.stdenv.mkDerivation {
  name = "sops-decrypted-files";
  version = "0.0.1";

  # 仅把 secrets/ 子树作为 src, 避免整个仓库被复制到 store
  # 并消除 Determinate Nix lazy-trees 的 "inefficient double copy" 警告
  src = builtins.path {
    path = ../..;
    name = "nixfiles-secrets";
    filter = path: _type:
      let
        rootPath = toString ../..;
        pathStr = toString path;
        relPath = pkgs.lib.removePrefix (rootPath + "/") pathStr;
      in
        # 保留根目录本身 (不加上会直接被 filter 拒绝)
        pathStr == rootPath
        # 保留 secrets 目录和其下所有内容
        || relPath == "secrets"
        || pkgs.lib.hasPrefix "secrets/" relPath;
  };

  buildInputs = with pkgs; [ age sops ];

  buildPhase = ''
    #!${pkgs.runtimeShell}
    mkdir -p $out

    export SOPS_AGE_KEY_FILE=${ageKeyFile}

    decryptSopsFile() {
      encrypted_file="$1"
      path_to_decrypted_file="$out/$2"

      # ensure that directory exists
      mkdir -p "$(dirname $path_to_decrypted_file)"

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
