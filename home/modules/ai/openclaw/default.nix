{ config, secretsUser, ... }:
let
  cfg = config.programs.openclawLocal;
in
{
  imports = [ ../../../../pkgs/openclaw ];

  # TG bot token 解密到 ~/.config/openclaw/tg-token
  programs.sops.decryptFiles = [{
    from = "secrets/users/${secretsUser}/.config/openclaw/tg-token.enc";
    to = ".config/openclaw/tg-token";
  }];

  programs.openclawLocal = {
    enable = true;
  };
}
