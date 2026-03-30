{ pkgs, config, ... }: {
  config.home.packages = with pkgs; [
    go
    postgresql
  ];

  config.home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/go";
  };
}
