{ pkgs, unstablePkgs, ... }: {
  config = {
    home.packages = (with pkgs; [
      pulumi
    ]) ++ (with unstablePkgs; [  ]);
  };
}
