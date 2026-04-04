{ lib, config, pkgs, secretsUser, ... }:

{
  config = {
    programs = {
      sops.decryptFiles = [
        {
          from = "secrets/users/${secretsUser}/paperclip.enc.zsh";
          to = ".paperclip.zsh";
        }
      ];

      pm2.services = [
        {
          name = "paperclip";
          script = pkgs.writeShellScriptBin "pm2-paperclip" ''
            #!/usr/bin/env bash
            set -e

            # Source project-specific secrets (sops-decrypted by home-manager activation)
            if [ -f "$HOME/.paperclip.zsh" ]; then
              source "$HOME/.paperclip.zsh"
            fi

            # Set PATH for volta tools
            export VOLTA_HOME="$HOME/.volta"
            export PATH="$VOLTA_HOME/bin:$HOME/.nix-profile/bin:$PATH"

            PAPERCLIP_DIR="${config.home.homeDirectory}/Github/paperclip"
            cd "$PAPERCLIP_DIR"

            # Install dependencies if needed
            if [ ! -d "node_modules" ]; then
              echo "Installing paperclip dependencies..."
              volta run pnpm install
            fi

            # Stop any existing dev server before starting
            echo "Stopping any existing Paperclip dev server..."
            volta run pnpm dev:stop 2>/dev/null || true

            # Start the server
            echo "Starting Paperclip server..."
            exec volta run pnpm dev
          '' + "/bin/pm2-paperclip";
          interpreter = "none";
          autorestart = true;
          max_restarts = 5;
          min_uptime = 30000;
          restart_delay = 10000;
          kill_timeout = 60000;
          env = {
            VOLTA_HOME = "${config.home.homeDirectory}/.volta";
            PAPERCLIP_HOME = "${config.home.homeDirectory}/.paperclip";
            PAPERCLIP_DEPLOYMENT_MODE = "authenticated";
            PAPERCLIP_DEPLOYMENT_EXPOSURE = "private";
            PAPERCLIP_PUBLIC_URL = "http://localhost:3100";
            PORT = "3100";
          };
        }
      ];
    };
  };
}
