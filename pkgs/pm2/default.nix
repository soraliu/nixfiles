{ pkgs, unstablePkgs, lib, config, ... }:
let
  cfg = config.programs.pm2;
  services = cfg.services;
  pathToConfig = pkgs.writeText "pm2.config.js" ''
    module.exports = {
      apps : ${builtins.toJSON services}
    }
  '';
in
{
  # imports = builtins.filter (el: el != null) [
  #   (lib.mkIf cfg.enable ../../home/modules/lang/nodejs.nix)
  # ];
  imports = [
    ../../home/modules/lang/nodejs.nix
  ];


  options.programs.pm2 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.doc "Whether to enable pm2.";
    };
    services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = [{
        name = "rclone";
        script = "path/to/script";
        interpreter = "${pkgs.zsh}/bin/zsh";
        autorestart = false;
        cron_restart = "*/1 * * * *";
      }];
      description = lib.doc "Run daemons";
    };
  };

  config.home = with lib; mkIf (cfg.enable && (length services > 0)) {
    packages = with pkgs; [ ];


    activation.initPm2 = hm.dag.entryAfter [ "initVolta" ] ''
      ${unstablePkgs.volta}/bin/volta run npm i -g pm2

      pm2_bin=~/.volta/bin/pm2

      # 获取配置中的服务名列表
      config_services=$(node -e "console.log(require('${pathToConfig}').apps.map(a => a.name).join(' '))")

      # 获取当前运行的服务名列表
      running_services=$($pm2_bin jlist 2>/dev/null | node -e "try { const list = JSON.parse(require('fs').readFileSync(0, 'utf-8')); console.log(list.map(p => p.name).join(' ')); } catch(e) { }" || echo "")

      # 删除不在配置中的服务
      for svc in $running_services; do
        if ! echo "$config_services" | grep -qw "$svc"; then
          $pm2_bin delete "$svc" 2>/dev/null || true
        fi
      done

      # 启动或重启配置中的服务（应用最新配置）
      $pm2_bin startOrRestart ${pathToConfig}

      # Setup PM2 to start on boot
      if [ "$(uname)" == "Darwin" ]; then
        mkdir -p $HOME/Library/LaunchAgents
      fi

      sudo $pm2_bin startup || true
      $pm2_bin save --force  # 保存当前状态（已精确清理后的服务列表）
    '';
  };
}
