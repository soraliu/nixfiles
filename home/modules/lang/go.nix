{ pkgs, unstablePkgs, config, ... }: {
  config.home.packages = (with pkgs; [
    go
    postgresql
  ]) ++ (with unstablePkgs; [
    rainfrog
  ]);

  config.home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/go";
  };
}
