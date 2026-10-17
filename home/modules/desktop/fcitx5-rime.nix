# 中文输入: fcitx5 + rime(rime-ice 方案); 配置与 darwin 侧鼠须管共用同一份 sops 密文,
# rime 用户目录 = ~/.local/share/fcitx5/rime
{ lib, pkgs, config, system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
  rimeDir = config.home.homeDirectory + "/.local/share/fcitx5/rime";
  rimeIceSrc = config.programs.rimeIce.src;
in
{
  imports = [ ../../../pkgs/rime-ice ];

  config = lib.mkIf (!isDarwin) {
    programs.rimeIce.enable = true;

    # HM 会写 GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS 到 hm-session-vars.sh, 经 .profile
    # 在 startwm.sh 阶段注入新 rdp 会话(老会话不刷新, 须注销重连)
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-rime qt6Packages.fcitx5-configtool ];
      # profile 里显式把 rime 加入输入法组(不写则组里只有默认键盘, rime 不可选)
      fcitx5.settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "rime";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "rime";
      };
    };

    # Rime 配置: 与 darwin rime 模块同源密文(squirrel.custom 是鼠须管专用, 不部署)
    programs.sops.decryptFiles = [
      { from = "secrets/.config/rime/default.custom.yaml.enc"; to = ".local/share/fcitx5/rime/default.custom.yaml"; }
      { from = "secrets/.config/rime/rime_ice.custom.yaml.enc"; to = ".local/share/fcitx5/rime/rime_ice.custom.yaml"; }
      { from = "secrets/.config/rime/custom_phrase.txt.enc"; to = ".local/share/fcitx5/rime/custom_phrase.txt"; }
    ];

    # systemd user service(graphical-session.target)在 XFCE+xrdp 不会被拉起, XDG
    # autostart 由 xfce4-session 保证; 用 i18n.inputMethod.package 保证与 addon 同包
    xdg.configFile."autostart/fcitx5.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Fcitx5
      Exec=${lib.getExe config.i18n.inputMethod.package}
    '';

    # rime-ice 方案部署(仿 darwin rime 模块白名单 rsync, 目标改 fcitx5 rime 目录)
    home.activation.deployRimeIceForFcitx5 = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      mkdir -p '${rimeDir}'
      version_marker='${rimeDir}/.rime-ice-version'
      current_version='${rimeIceSrc}'
      if [ -f "$version_marker" ] && [ "$(cat "$version_marker")" = "$current_version" ]; then
        echo "rime-ice is up to date"
      else
        echo "Deploying rime-ice from $current_version..."
        ${pkgs.rsync}/bin/rsync -a --chmod=u+w \
          --include='*.schema.yaml' \
          --include='*.dict.yaml' \
          --include='default.yaml' \
          --include='symbols*.yaml' \
          --include='cn_dicts/***' \
          --include='en_dicts/***' \
          --include='lua/***' \
          --include='opencc/***' \
          --exclude='*' \
          '${rimeIceSrc}/' '${rimeDir}/'
        echo '${rimeIceSrc}' > "$version_marker"
        echo "rime-ice deployed"
      fi
    '';
  };
}
