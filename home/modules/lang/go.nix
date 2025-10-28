{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    go
    postgresql
    buf
  ];

  config.home.sessionVariables = {
    GOPATH = "$HOME/go";
  };
}
