{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    nodejs_20 # nodejs, npm
    yarn-berry # yarn berry
  ];
  config.home.sessionVariables = {
    NODEJS_PATH = "${pkgs.nodejs_20}";
  };
  config.programs.sops.decryptFiles = [{
    from = "secrets/.npmrc.enc";
    to = ".npmrc";
  }];
}
