{ pkgs, unstablePkgs, config, ... }: {
  config.home.packages = (with pkgs; [
    go
    postgresql
  ]) ++ (with unstablePkgs; [
    lazysql
  ]);

  config.home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/go";
  };
}
