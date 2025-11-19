{ pkgs, unstablePkgs, ... }: {
  config = {
    home.packages = (with pkgs; [
      ansible
    ]) ++ (with unstablePkgs; [
      pulumi
      pulumiPackages.pulumi-nodejs
    ]);
  };
}
