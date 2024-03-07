{ pkgs, lib, config, ... }: {
  config.home.packages = with pkgs; [
    git-open
    git-extras          # extra git alias
    # bfg-repo-cleaner    # big file cleaner for git
  ];

  config.programs.git = {
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

  config.programs.gh = {
    gitCredentialHelper.enable = true;
  };

  config.programs.zsh.oh-my-zsh.plugins = with lib; mkIf config.programs.zsh.oh-my-zsh.enable [
    "git"
    "git-extras"
  ];

  # programs.sops = {
  #   decryptFiles = [{
  #     from = "secrets/.git-credentials.enc";
  #     to = ".git-credentials";
  #   }];
  # };
}
