{ pkgs, config, lib, secretsUser, openclawPackage ? null, ... }: {
  config = lib.mkMerge [
    {
    # nix-openclaw provides openclaw package (via overlay)
    home.packages = lib.optional (openclawPackage != null) openclawPackage;

    home.sessionVariables = {
      OPENCLAW_HOME = "${config.home.homeDirectory}/.openclaw";
    };

    # TG bot token 解密到 ~/.config/openclaw/tg-token
    programs.sops.decryptFiles = [{
      from = "secrets/users/${secretsUser}/.config/openclaw/tg-token.enc";
      to = ".config/openclaw/tg-token";
    }];
    }
    (lib.mkIf (openclawPackage != null) {
      # 排除 clawbot profile 已独立安装的工具，避免 buildEnv 路径冲突
      # git 由 nix-openclaw 在 programs.git.enable 时自动排除
      programs.openclaw.excludeTools = [ "bird" ];
      programs.openclaw.package = openclawPackage;

      # nix-openclaw service configuration — launchd/systemd managed
      programs.openclaw.enable = true;
      # 显式声明 default instance，绕过 nix-openclaw config.nix 中
      # defaultInstance 手动构建时遗漏 appDefaults.nixMode 的 bug
      programs.openclaw.instances.default = {};
      programs.openclaw.config = {
        gateway = {
          mode = "local";
        };
        channels.telegram = {
          tokenFile = "${config.home.homeDirectory}/.config/openclaw/tg-token";
          allowFrom = [ 920355045 ];
        };
      };
    })
  ];
}
