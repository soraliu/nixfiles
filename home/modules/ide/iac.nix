{ pkgs, unstablePkgs, ... }: {
  config = {
    home.packages = (with pkgs; [
    ]) ++ (with unstablePkgs; [
      pulumi
      pulumiPackages.pulumi-nodejs
    ]);
  };
}
