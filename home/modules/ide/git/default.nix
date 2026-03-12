{ pkgs, unstablePkgs, lib, secretsUser, userProfile, ... }:
let
  # Read-only credential helper - only reads from files, doesn't try to write
  git-credential-store-readonly = pkgs.writeShellScriptBin "git-credential-store-readonly" ''
    # Only handle get operations, ignore store/erase
    if [ "$1" = "get" ]; then
      exec ${pkgs.git}/bin/git credential-store --file ~/.git-credentials get
    fi
    # store and erase operations exit directly, no error
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
          user.name = lib.mkDefault userProfile.gitName;
          user.email = lib.mkDefault userProfile.gitEmail;
          alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          alias.rg = "reflog --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          init.defaultBranch = "main";
          push.default = "current";
          pull.rebase = "true";
          hub.protocol = "https";
          merge.conflictStyle = "diff3";
          core.quotePath = "off";
        } // (if pkgs.stdenv.isDarwin then {} else {
          # Use custom read-only credential helper
          credential.helper = "${git-credential-store-readonly}/bin/git-credential-store-readonly";
        });
      };

      gh = {
        enable = true;
        # Linux: use ~/.git-credentials (credential.helper = "store")
        # macOS: use gh's credential helper (more secure, integrated with Keychain)
        gitCredentialHelper.enable = pkgs.stdenv.isDarwin;
      };

      sops = {
        decryptFiles = [{
          from = "secrets/users/${secretsUser}/.git-credentials.enc";
          to = ".git-credentials";
        } {
          from = "secrets/users/${secretsUser}/.config/hub";
          to = ".config/hub";
        }];
      };
    };
  };
}
