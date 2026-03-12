{ unstablePkgs, ... }: {
  config.home.packages = with unstablePkgs; [
    just-lsp
  ];
}
