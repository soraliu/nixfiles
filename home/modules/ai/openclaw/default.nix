{ pkgs, config, ... }: {
  config = {
    home.packages = with pkgs; [
      nodejs_22
      pnpm
    ];

    programs.pm2.services = [{
      name = "openclaw";
      script = "${config.home.homeDirectory}/.openclaw/node_modules/.bin/openclaw";
      args = "gateway";
      cwd = "${config.home.homeDirectory}/.openclaw";
      exp_backoff_restart_delay = 3000;
      max_restarts = 5;
      min_uptime = 5000;
    }];

    # 初始化 OpenClaw
    home.activation.initOpenclaw = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.git}/bin:$PATH"

      # 克隆 clawfiles 到 ~/.openclaw（如果不存在）
      if [ ! -d "${config.home.homeDirectory}/.openclaw/.git" ]; then
        echo "Cloning clawfiles repository..."
        if [ -d "${config.home.homeDirectory}/.openclaw" ]; then
          rm -rf "${config.home.homeDirectory}/.openclaw"
        fi
        git clone https://github.com/soraliu/clawfiles.git "${config.home.homeDirectory}/.openclaw"
      fi
    '';
  };
}
