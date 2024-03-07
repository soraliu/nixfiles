{ config, pkgs, ... }: {
  
  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  home.file = {
    ".p10k.zsh".source = ./.p10k.zsh;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    syntaxHighlighting = {
      enable = true;
    };

    initExtraFirst = builtins.concatStringsSep "\n\n\n" [
      (builtins.readFile ./init.zsh)
      # theme configuration
      ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ~/.p10k.zsh
      ''
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [
        # vi-mode have to be in front of sudo to avoid conflict
        "colorize"
        "vi-mode"
        "sudo"
        "extract"
        "catimg"
        "autojump"
        "history-substring-search"
        "docker"
        "docker-compose"
        "kubectl"

        # tools
        "jsontools"
        # "zsh-hub"
        # "zsh-ghf"

        # productivity
        "colored-man-pages"                   # adds colors to manpages
        # this plugin cost too much time
        # command-not-found                   # suggests package name with relevant command
        "copypath"                            # copies selected path to clipboard
        "copyfile"                            # copies selected file content to clipboard
        "cp"                                  # cp with progress bar (rsync))
        "dircycle"                            # hotkeys for cycling directories
        "web-search"                          # cli search

        # build
        "node"

        # search
        # fzf
        # fzf-zsh

      ];
    };
  };
}
