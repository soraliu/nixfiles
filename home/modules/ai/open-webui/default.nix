{ unstablePkgs, lib, config, ... }: {
  config = {
    home.packages = with unstablePkgs; [
      open-webui
    ];
  };
}
