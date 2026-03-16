{ unstablePkgs, config, lib, ... }: with unstablePkgs; let
  homeDir = config.home.homeDirectory;
  # com.googlecode.iterm2 是目录，实际配置文件为其中的 com.googlecode.iterm2.plist
  configDir = homeDir + "/.config/iterm2/com.googlecode.iterm2";
  plistFile = configDir + "/com.googlecode.iterm2.plist";
  decryptedFile = homeDir + "/.config/iterm2/com.googlecode.iterm2.plist.decrypted";
in  {
  config = {
    # 解密 iTerm2 plist 到临时位置
    programs.sops.decryptFiles = [{
      from = "secrets/.config/iterm2/com.googlecode.iterm2.plist.enc";
      to = ".config/iterm2/com.googlecode.iterm2.plist.decrypted";
    }];

    # 将解密后的 plist 复制到 iTerm2 配置目录
    home.activation.copyIterm2Config = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      # 如果 configDir 是旧的 symlink（如指向 gdrive），先移除
      if [ -L "${configDir}" ]; then
        echo "Removing old iTerm2 symlink: ${configDir}"
        unlink "${configDir}"
      fi

      # 确保配置目录存在
      mkdir -p "${configDir}"

      if [ -f "${decryptedFile}" ]; then
        # 如果目标 plist 已存在，先备份
        if [ -f "${plistFile}" ]; then
          backup="${plistFile}.backup.$(date +%Y%m%d_%H%M%S)"
          echo "Backing up existing iTerm2 plist to $backup"
          mv "${plistFile}" "$backup"
        fi

        cp "${decryptedFile}" "${plistFile}"
        echo "iTerm2 plist copied to ${plistFile}"
      else
        echo "Warning: decrypted iTerm2 plist not found at ${decryptedFile}"
      fi

      # 告诉 iTerm2 从自定义目录加载配置
      defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${configDir}" || \
        echo "Warning: failed to set iTerm2 PrefsCustomFolder"
      defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true || \
        echo "Warning: failed to enable iTerm2 LoadPrefsFromCustomFolder"
    '';
  };
}
