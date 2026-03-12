{ unstablePkgs, config, ... }: with unstablePkgs; let
  pathToConfigLink = config.home.homeDirectory + "/.config/iterm2/com.googlecode.iterm2";
in  {
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/com.googlecode.iterm2";
    link = pathToConfigLink;
  }];
}
