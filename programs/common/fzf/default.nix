{ pkgs, ... }: {
  # Github: https://github.com/junegunn/fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.sessionVariables = {
    FZF_DEFAULT_OPTS = "--height=70% --reverse";
    # Preview file content using bat (https://github.com/sharkdp/bat)
    FZF_CTRL_T_OPTS = "
      --preview 'bat -n --color=always {}'
      --bind 'ctrl-/:change-preview-window(down|hidden|)'
    ";
    FZF_ALT_C_OPTS = "--preview 'tree -C {}'";
    FZF_CTRL_R_OPTS = "
      --preview 'echo {}' --preview-window up:3:hidden:wrap
      --bind 'ctrl-/:toggle-preview'
      --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
      --color header:italic
      --header 'Press CTRL-Y to copy command into clipboard'
    ";
  };
}
