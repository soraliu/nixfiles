{ pkgs, unstablePkgs, lib, ... }:
let
  # 只读的 credential helper - 只从文件读取，不尝试写入
  git-credential-store-readonly = pkgs.writeShellScriptBin "git-credential-store-readonly" ''
    # 只处理 get 操作，忽略 store/erase
    if [ "$1" = "get" ]; then
      exec ${pkgs.git}/bin/git credential-store --file ~/.git-credentials get
    fi
    # store 和 erase 操作直接退出，不报错
    exit 0
  '';
in
{
  config = {
    home.packages = (with pkgs; [
      git-open
      hub                 # Command-line wrapper for git that makes you better at GitHub
      git-extras          # extra git alias
      diff-so-fancy       # good-looking diffs filter for git
      # bfg-repo-cleaner    # big file cleaner for git
    ]) ++ (with unstablePkgs; [ lazygit ]) ++ [ git-credential-store-readonly ];

    programs = {
      git = {
        enable = true;
        settings = {
          user.name = "Sora Liu";
          user.email = "soraliu.dev@gmail.com";
          alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          alias.rg = "reflog --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          init.defaultBranch = "main";
          push.default = "current";
          pull.rebase = "true";
          hub.protocol = "https";
          merge.conflictStyle = "diff3";
          core.quotePath = "off";
        } // (if pkgs.stdenv.isDarwin then {} else {
          # 使用自定义的只读 credential helper
          credential.helper = "${git-credential-store-readonly}/bin/git-credential-store-readonly";
        });
      };

      gh = {
        enable = true;
        # Linux: 使用 ~/.git-credentials (credential.helper = "store")
        # macOS: 使用 gh 的 credential helper (更安全，集成 Keychain)
        gitCredentialHelper.enable = pkgs.stdenv.isDarwin;
      };

      sops = {
        decryptFiles = [{
          from = "secrets/.git-credentials.enc";
          to = ".git-credentials";
        } {
          from = "secrets/.config/hub";
          to = ".config/hub";
        }];
      };
    };
  };
}
