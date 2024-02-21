{ config, pkgs, lib, ... }: let 
  placeholderGitCredentials = pkgs.writeText ".git-credentials" "";
in {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "root";
  home.homeDirectory = "/root";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    sops
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".git-credentials".source = placeholderGitCredentials;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/root/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {};

  # Custom activation scripts
  home.activation.decryptSopsFiles = let
    scriptPath = "${pkgs.writeScript "decrypt-sops-files.sh" ''
      #!${pkgs.runtimeShell}

      encrypted_file="$1"

      target_dir_or_file="$2"
      if [ -z "$target_dir_or_file" ]; then
        target_dir_or_file=$(dirname "$encrypted_file")
      fi

      target_file="$target_dir_or_file"
      if [ -d "$target_file" ]; then
        target_file="$target_dir_or_file/$(basename "$encrypted_file" .enc)"
      fi

      # ensure that directory exists
      mkdir -p "$(basename $target_file)"

      ${pkgs.sops}/bin/sops --decrypt "$encrypted_file" > "$target_file"

      echo "$encrypted_file -> $target_file"
    ''}";
  in lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "🟡🟡🟡 Start to decrypt files..."

    project_root_dir="${builtins.toPath ../..}"

    export GPG_TTY=$(tty)
    export SOPS_GPG_EXEC=${pkgs.gnupg}/bin/gpg

    ${scriptPath} "$project_root_dir/secrets/.git-credentials.enc" ${placeholderGitCredentials}

    echo "🎉🎉🎉 Finish decrypting!"
  '';
}
