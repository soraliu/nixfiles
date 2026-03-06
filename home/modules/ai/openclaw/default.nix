{ pkgs, unstablePkgs, config, lib, ... }: {
  config = {
    home.sessionVariables = {
      OPENCLAW_HOME = "${config.home.homeDirectory}/.openclaw";
    };

    programs.pm2.services = [{
      name = "openclaw";
      script = "${config.home.homeDirectory}/.volta/bin/openclaw";
      args = "gateway";
      cwd = "${config.home.homeDirectory}/.openclaw";
      env = {
        OPENCLAW_HOME = "${config.home.homeDirectory}/.openclaw";
        PATH = "${config.home.homeDirectory}/.volta/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
      };
      exp_backoff_restart_delay = 3000;
      max_restarts = 5;
      min_uptime = 5000;
    }];

    home.activation.initOpenclaw = lib.hm.dag.entryAfter [ "initVolta" ] ''
      export PATH="${pkgs.git}/bin:$HOME/.volta/bin:$PATH"

      # 克隆 clawfiles 到 ~/.openclaw（如果不存在）
      if [ ! -d "${config.home.homeDirectory}/.openclaw/.git" ]; then
        echo "Cloning clawfiles repository..."
        if [ -d "${config.home.homeDirectory}/.openclaw" ]; then
          rm -rf "${config.home.homeDirectory}/.openclaw"
        fi
        ${pkgs.git}/bin/git clone https://github.com/soraliu/clawfiles.git "${config.home.homeDirectory}/.openclaw"
      else
        echo "clawfiles already cloned, pulling latest..."
        ${pkgs.git}/bin/git -C "${config.home.homeDirectory}/.openclaw" pull --ff-only || true
      fi
    '';
  };
}
