{ pkgs, config, lib, ... }: {
  config = {
    # nix-openclaw provides openclaw package (via overlay)
    home.packages = [ pkgs.openclaw ];

    home.sessionVariables = {
      OPENCLAW_HOME = "${config.home.homeDirectory}/.openclaw";
    };

    # nix-openclaw service configuration — enabled and managed by launchd/systemd, no longer depends on PM2
    # User needs to add Telegram token, API key and other secrets before uncommenting
    # programs.openclaw = {
    #   enable = true;
    #   config = {
    #     gateway = {
    #       mode = "local";
    #       auth.token = ""; # or set OPENCLAW_GATEWAY_TOKEN environment variable
    #     };
    #     channels.telegram = {
    #       tokenFile = ""; # Telegram bot token file path
    #       allowFrom = []; # Telegram user ID
    #     };
    #   };
    # };

    # home.activation.initOpenclaw = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    #   export PATH="${pkgs.git}/bin:$PATH"

    #   # Clone clawfiles to ~/.openclaw (if not exists)
    #   if [ ! -d "${config.home.homeDirectory}/.openclaw/.git" ]; then
    #     echo "Cloning clawfiles repository..."
    #     if [ -d "${config.home.homeDirectory}/.openclaw" ]; then
    #       rm -rf "${config.home.homeDirectory}/.openclaw"
    #     fi
    #     ${pkgs.git}/bin/git clone https://github.com/soraliu/clawfiles.git "${config.home.homeDirectory}/.openclaw"
    #   else
    #     echo "clawfiles already cloned, pulling latest..."
    #     ${pkgs.git}/bin/git -C "${config.home.homeDirectory}/.openclaw" pull --ff-only || true
    #   fi
    # '';
  };
}
