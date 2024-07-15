{ pkgs, ... }: with pkgs; {
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/.snipaste";
    link = (builtins.getEnv "HOME") + "/.snipaste";
  }];
}
