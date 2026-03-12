{ unstablePkgs, config, ... }: with unstablePkgs; let
  pathToConfigLink = config.home.homeDirectory + "/.config/karabiner";
in  {
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/karabiner";
    link = pathToConfigLink;
  }];
}
