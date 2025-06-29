{ pkgs, config, lib, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        nebula
      ];

      activation.outputNebulaSudoers = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        #/usr/bin/env bash
        echo "Pls adding nebula to sudoers manually"
        echo "echo '${config.home.username} ALL=(ALL) NOPASSWD: ${pkgs.nebula}/bin/nebula' | sudo tee /etc/sudoers.d/nebula"
      '';
    };

    programs = {
      sops = {
        decryptFiles = [
          {
            from = "secrets/.config/nebula/config.enc.yml";
            to = ".config/nebula/config.yml";
          }
          {
            from = "secrets/.config/nebula/host.enc.crt";
            to = ".config/nebula/host.crt";
          }
          {
            from = "secrets/.config/nebula/host.enc.key";
            to = ".config/nebula/host.key";
          }
          {
            from = "secrets/.config/nebula/ca.enc.crt";
            to = ".config/nebula/ca.crt";
          }
        ];
      };
      pm2 = {
        services = [{
          name = "nebula";
          script = "bash";
          args = "-c '/usr/bin/sudo ${pkgs.nebula}/bin/nebula -config ${config.home.homeDirectory}/.config/nebula/config.yml'";
          exp_backoff_restart_delay = 100;
          max_restarts = 3;
        }];
      };
    };
  };
}
