{ pkgs, config, lib, secretsUser, ... }:
let
  rimeDir = config.home.homeDirectory + "/Library/Rime";
  rimeIceSrc = config.programs.rimeIce.src;
in
{
  imports = [
    ../../../../../pkgs/rime-ice
  ];

  config = {
    programs.rimeIce.enable = true;

    # 核心用户配置：sops 解密后通过 home.file 部署为 symlink
    programs.sops.decryptFiles = [
      { from = "secrets/users/${secretsUser}/.config/rime/default.custom.yaml.enc"; to = "Library/Rime/default.custom.yaml"; }
      { from = "secrets/users/${secretsUser}/.config/rime/rime_ice.custom.yaml.enc"; to = "Library/Rime/rime_ice.custom.yaml"; }
      { from = "secrets/users/${secretsUser}/.config/rime/squirrel.custom.yaml.enc"; to = "Library/Rime/squirrel.custom.yaml"; }
      { from = "secrets/users/${secretsUser}/.config/rime/custom_phrase.txt.enc"; to = "Library/Rime/custom_phrase.txt"; }
    ];

    # sync/ 通过 linker 指向 Google Drive（复用现有基础设施同步用户词库）
    programs.linker.links = [
      {
        source = "gdrive:Sync/Config/Darwin/rime/sync";
        link = rimeDir + "/sync";
      }
    ];

    # 确保 ~/Library/Rime 是真实可写目录（在 linkGeneration 之前移除旧的整目录 symlink）
    home.activation.prepareRimeDir = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      if [ -L '${rimeDir}' ]; then
        echo "Removing old Rime symlink, creating real directory..."
        unlink '${rimeDir}'
      fi
      mkdir -p '${rimeDir}'
    '';

    # 部署 rime-ice 上游方案文件（白名单模式，仅同步需要的 schema/dict/lua/opencc）
    home.activation.deployRimeIce = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      version_marker='${rimeDir}/.rime-ice-version'
      current_version='${rimeIceSrc}'

      if [ -f "$version_marker" ] && [ "$(cat "$version_marker")" = "$current_version" ]; then
        echo "rime-ice is up to date"
      else
        echo "Deploying rime-ice from $current_version..."
        ${pkgs.rsync}/bin/rsync -a --chmod=u+w \
          --include='*.schema.yaml' \
          --include='*.dict.yaml' \
          --include='default.yaml' \
          --include='squirrel.yaml' \
          --include='weasel.yaml' \
          --include='symbols*.yaml' \
          --include='cn_dicts/***' \
          --include='en_dicts/***' \
          --include='lua/***' \
          --include='opencc/***' \
          --exclude='*' \
          '${rimeIceSrc}/' '${rimeDir}/'
        echo '${rimeIceSrc}' > "$version_marker"
        echo "rime-ice deployed"
      fi
    '';
  };
}
