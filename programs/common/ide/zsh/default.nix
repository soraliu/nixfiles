{ pkgs, lib, ... }: {
  imports = [
    ../search/pet
    ../search/fzf

    ../../fs/sops
  ];

  programs = {
    zsh = {
      enable = true;
      history = {
        size = 100000;
        save = 100000;
      };

      initExtraFirst = builtins.concatStringsSep "\n\n\n" [
        (builtins.readFile ./init.zsh)
        (builtins.readFile ./fn.zsh)
        (builtins.readFile ./bind-keys.zsh)
      ];

      initExtra = builtins.concatStringsSep "\n\n\n" [
        ''
          source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
        ''

        (builtins.readFile ./zinit.zsh)
        (builtins.readFile ./alias.zsh)
      ];
    };

    sops = {
      decryptFiles = [{
        from = "secrets/.keys.enc.zsh";
        to = ".keys.zsh";
      }];
    };
  };

  home = {
    packages = with pkgs; [
      autojump                      # Exec `j` command
    ];

    file = {
      ".p10k.zsh".source = ./.p10k.zsh;
    };

    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };

    activation.initZsh = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $HOME/.cache/zinit/completions
    '';
  };


}
