{ config, pkgs, ... }: {
  imports = [
  ];

  # programs.zsh = {
  #   enable = true;

  #   oh-my-zsh = {
  #     enable = true;
  #   };
  # };

  home.packages = with pkgs; [
    bash
    bash-completion
  ];

  programs.bash = {
    enable = true;
    enableCompletion = false;

    bashrcExtra = ''
# [ -f ~/.fzf.bash ] && source ~/.fzf.bash
# . "$HOME/.cargo/env"

if [ -f "${pkgs.bash-completion.outPath}/etc/profile.d/bash_completion.sh" ]; then
    . "${pkgs.bash-completion.outPath}/etc/profile.d/bash_completion.sh"
fi

    '';
  };
}
