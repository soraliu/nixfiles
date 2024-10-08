{ unstablePkgs, ... }: with unstablePkgs; let
  pathToConfigLink = (builtins.getEnv "HOME") + "/.config/iterm2/com.googlecode.iterm2";
in  {
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/com.googlecode.iterm2";
    link = pathToConfigLink;
  }];
}
