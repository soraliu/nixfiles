{ pkgs, lib, config, ... }:

let
  cfg = config.programs.sshd-authorize;
  keyDir = cfg.keyDir;
  homeSubdir = lib.removePrefix "${config.home.homeDirectory}/" keyDir;

  sshdConfig = pkgs.writeText "sshd_config" ''
    Port 22
    HostKey ${keyDir}/ssh_host_ed25519_key
    HostKey ${keyDir}/ssh_host_rsa_key

    PasswordAuthentication yes
    PermitRootLogin prohibit-password
    AuthorizedKeysFile ${keyDir}/authorized_keys
    UseDNS no

    X11Forwarding no
    MaxAuthTries 3
  '';

  sshdStartScript = pkgs.writeText "sshd-start-script.sh" ''
    #!/bin/sh
    set -e

    mkdir -p ${keyDir}
    mkdir -p /var/empty

    # 生成 host key（删除旧文件后重新生成，避免交互式询问）
    rm -f ${keyDir}/ssh_host_ed25519_key ${keyDir}/ssh_host_ed25519_key.pub
    rm -f ${keyDir}/ssh_host_rsa_key ${keyDir}/ssh_host_rsa_key.pub
    ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${keyDir}/ssh_host_ed25519_key -N "" -q
    ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f ${keyDir}/ssh_host_rsa_key -N "" -q

    chmod 600 ${keyDir}/ssh_host_ed25519_key
    chmod 600 ${keyDir}/ssh_host_rsa_key
    chmod 644 ${keyDir}/ssh_host_ed25519_key.pub
    chmod 644 ${keyDir}/ssh_host_rsa_key.pub

    # 处理 authorized_keys: sops 解密后是符号链接指向 nix store（权限 644），
    # sshd 要求 authorized_keys 必须是 600 权限，所以需要复制到用户目录
    SRC_KEYS="${keyDir}/authorized_keys"
    if [ -L "$SRC_KEYS" ]; then
      CONTENT=$(cat "$SRC_KEYS")
      rm -f ${keyDir}/authorized_keys
      echo "$CONTENT" > ${keyDir}/authorized_keys
      chmod 600 ${keyDir}/authorized_keys
    elif [ -f "$SRC_KEYS" ]; then
      cp -f "$SRC_KEYS" ${keyDir}/authorized_keys
      chmod 600 ${keyDir}/authorized_keys
    fi

    exec ${pkgs.openssh}/bin/sshd -D -f ${sshdConfig} -E ${keyDir}/sshd.log
  '';
in
{
  imports = [ ../pm2 ];

  options.programs.sshd-authorize = {
    enable = lib.mkEnableOption "sshd authorized_keys management";
    keyDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/ssh";
      description = "SSH 密钥和配置目录";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ openssh ];

    # sshd_config 文件
    programs.sshd-authorize.sshdConfig = sshdConfig;

    # sops 解密 authorized_keys
    # to 是相对于 $HOME 的路径，pkgs/sops/default.nix 通过 home.file."<to>" 部署
    programs.sops.decryptFiles = [{
      from = "secrets/.config/ssh/authorized_keys.enc";
      to = "${homeSubdir}/authorized_keys";
    }];

    # pm2 启动 sshd
    programs.pm2.services = [{
      name = "sshd";
      script = sshdStartScript;
      exp_backoff_restart_delay = 100;
      max_restarts = 3;
      autorestart = true;
    }];
  };
}
