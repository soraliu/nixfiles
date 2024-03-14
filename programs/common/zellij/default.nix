{ pkgs, lib, config, ... }: {
  programs = {
    zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home = {
    file = {
      ".config/zellij/config.kdl".source = ./config.kdl;
      ".config/zellij/layouts/default.kdl".source = ./layouts/default.kdl;
    };
    sessionVariables = {
      ZELLIJ_CONFIG_DIR = "$HOME/.config/zellij";
    };

    activation.initZellijPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -e

      plugin_url="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
      path_to_plugin_file=$HOME/.config/zellij/plugins/zjstatus.wasm

      if [ ! -f $path_to_plugin_file ]; then
        mkdir -p $(dirname $path_to_plugin_file)
        ${pkgs.wget}/bin/wget "$plugin_url" -O $path_to_plugin_file
      fi
    '';
  };
}
