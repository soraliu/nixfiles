{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    go
  ];

  config.home.sessionVariables = {
    GOPATH = "$HOME/go";
  };
}
