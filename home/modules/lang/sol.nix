{ unstablePkgs, ... }: {
  config.home.packages = with unstablePkgs; [
    foundry
  ];
}
