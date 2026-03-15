# 配置层：导入 pkgs/openclaw 可复用模块，配置 clawfiles clone + 具体参数
# pkgs/openclaw 负责 pnpm 安装 + launchd/systemd 服务
# 本模块负责 clawfiles repo 管理 + sops 解密 + 具体配置值
{ pkgs, config, lib, secretsUser, ... }:

let
  cfg = config.programs.openclawLocal;
  homeDir = config.home.homeDirectory;
  clawfilesDir = "${cfg.stateDir}";
in
{
  imports = [ ../../../../pkgs/openclaw ];

  # TG bot token 解密到 ~/.config/openclaw/tg-token
  programs.sops.decryptFiles = [{
    from = "secrets/users/${secretsUser}/.config/openclaw/tg-token.enc";
    to = ".config/openclaw/tg-token";
  }];

  # 配置 openclaw 包模块
  programs.openclawLocal = {
    enable = true;
    configPath = "${clawfilesDir}/openclaw.json";
  };
}
