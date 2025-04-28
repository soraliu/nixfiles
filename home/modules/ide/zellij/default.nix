{ pkgs, unstablePkgs, lib, config, isMobile, ... }: let
  pluginTpl = ''
    pane size=1 borderless=true {
      plugin location="file:~/.config/zellij/plugins/zjstatus.wasm" {

        ${if isMobile then ''
          format_left "#[fg=#89B4FA,bold]{mode}"
          format_center "{tabs}"
        '' else ''
          format_left "#[fg=#181825,bg=#b1bbfa] [{session}] #[fg=#89B4FA,bold]{mode}"
          format_center "{tabs}"
          format_right "{datetime}"
        ''}

        format_space "#[bg=#181825]"

        hide_frame_for_single_pane "false"

        mode_normal             "#[fg=#181825,bg=#AFFA00] Normal "
        mode_pane               "#[fg=#ffffffe,bg=#af0000] Pane "
        mode_move               "#[fg=#ffffffe,bg=#009688] Move "
        mode_resize             "#[fg=#181825,bg=#CDDC39] Resize "
        mode_search             "#[fg=#181825,bg=#FFEB3B] Search "
        mode_enter_search       "#[fg=#181825,bg=#FFEB3B] Enter Search "
        mode_rename_pane        "#[fg=#181825,bg=#FFEB3B] Rename Pane "
        mode_rename_tab         "#[fg=#181825,bg=#FFEB3B] Rename Tab "

        tab_normal              "#[fg=#9e9e9e,bg=#4C4C59] {index}  {name} "
        tab_normal_fullscreen   "#[fg=#dadada,bg=#4C4C59] {index}  {name} [F] "
        tab_normal_sync         "#[fg=#dadada,bg=#4C4C59] {index}  {name} [S] "
        tab_active              "#[fg=#181825,bg=#ffffff,bold] {index}  {name} "
        tab_active_fullscreen   "#[fg=#181825,bg=#ffffff,bold] {index}  {name} [F] "
        tab_active_sync         "#[fg=#181825,bg=#ffffff,bold] {index}  {name} [S] "

        datetime          "#[fg=#181825,bg=#b1bbfa,italic] {format} "
        datetime_format   "%A, %m-%d %H:%M:%S"
        datetime_timezone "Asia/Shanghai"
      }
    }
  '';
  metricsTpl = ''
    pane size="60%" split_direction="vertical" {
      ${if isMobile then "" else ''
        pane command="bash" size="40%" {
          args "-c" "(bandwhich 2>/dev/null) || sudo bandwhich"
          start_suspended true
        }
      ''}
      pane command="joshuto" size="${if isMobile then "50%" else "40%"}" {
        start_suspended true
      }
      pane command="dua" size="${if isMobile then "50%" else "20%"}" {
        args "interactive" "${config.home.homeDirectory}"
        start_suspended true
      }
    }
    pane command="htop" size="40%" focus=true {}
  '';
  codingLayout = ''
    layout {
      tab hide_floating_panes=true {
        pane size="75%" command="~/.nix-profile/bin/nvim" focus=true {}
        pane name="Command:" size="25%" {}

        ${pluginTpl}
      }
    }
  '';
  metricsLayout = ''
    layout {
      tab cwd="~" name="Metrics" hide_floating_panes=true {
        ${metricsTpl}

        ${pluginTpl}
      }
    }
  '';
  defaultLayout = ''
    layout {
      cwd "~"
      tab name="Metrics" hide_floating_panes=true {
        ${metricsTpl}
      }

      tab name="Tab" hide_floating_panes=true {
        pane
      }

      default_tab_template name="Tab" {
        children

        ${pluginTpl}
      }
    }
  '';
in {
  home.packages = with unstablePkgs; [
    zellij
  ];

  home = {
    file = {
      ".config/zellij/config.kdl".source              = ./config.kdl;
      ".config/zellij/layouts/default.kdl".text       = defaultLayout;
      ".config/zellij/layouts/coding.kdl".text        = codingLayout;
      ".config/zellij/layouts/metrics.kdl".text       = metricsLayout;
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
