{ pkgs, ... }: {
  config = {
    home.packages = with pkgs; [
      git-open
      git-extras          # extra git alias
      diff-so-fancy       # good-looking diffs filter for git
      # bfg-repo-cleaner    # big file cleaner for git
    ];

    programs = {
      git = {
        enable = true;
        userName = "Sora Liu";
        userEmail = "soraliu.dev@gmail.com";

        aliases = {
          lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          rg = "reflog --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };

        extraConfig = {
          init.defaultBranch = "main";
          push.default = "current";
          pull.rebase = "true";
          hub.protocol = "https";
          credential.helper = "store";
        };
      };

      gh = {
        gitCredentialHelper.enable = true;
      };

      sops = {
        decryptFiles = [{
          from = "secrets/.git-credentials.enc";
          to = ".git-credentials";
        }];
      };
    };
  };
}
