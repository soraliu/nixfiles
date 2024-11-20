{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    nodejs_22 # nodejs, npm
    yarn-berry # yarn berry
  ];
  config.home.sessionVariables = {
    NODEJS_PATH = "${pkgs.nodejs_22}";
  };
  config.programs.sops.decryptFiles = [{
    from = "secrets/.npmrc.enc";
    to = ".npmrc";
  }];
}
