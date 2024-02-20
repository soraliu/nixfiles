{ pkgs, ... }: {
  programs.bash = {
    enable = true;
    enableCompletion = true;

    bashrcExtra = ''
GPG_TTY=$(tty)
export GPG_TTY
    '';
  };
}
