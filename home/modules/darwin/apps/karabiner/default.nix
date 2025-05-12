{ unstablePkgs, ... }: with unstablePkgs; let
  pathToConfigLink = (builtins.getEnv "HOME") + "/.config/karabiner";
in  {
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/karabiner";
    link = pathToConfigLink;
  }];
}
