{ unstablePkgs, ... }: {
  config = {
    home.packages = with unstablePkgs; [
      claude-code
    ];
  };
}
