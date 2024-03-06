{ pkgs, ... }: {
  programs.bash = {
    enable = true;
    enableCompletion = true;

    bashrcExtra = ''
# [ -f ~/.fzf.bash ] && source ~/.fzf.bash
# . "$HOME/.cargo/env"
    '';
  };
}
