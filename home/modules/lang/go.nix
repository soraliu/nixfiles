{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    go
    postgresql
  ];

  config.home.sessionVariables = {
    GOPATH = "$HOME/go";
  };
}
