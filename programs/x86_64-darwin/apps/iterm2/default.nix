{ unstablePkgs, ... }: with unstablePkgs; let
in  {
  config = {
    home.packages = [
      iterm2
    ];
  };
}
