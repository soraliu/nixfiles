{ pkgs, ... }: {
  programs.git = {
    enable = true;
    userName = "Sora Liu";
    userEmail = "soraliu.dev@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      push.default = "current";
      pull.rebase = "true";
    };

    aliases = {
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      rg = "reflog --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };
}
