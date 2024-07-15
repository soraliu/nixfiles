{ pkgs, ... }: with pkgs; {
  config.programs.linker.links = [{
    source = "gdrive:Sync/Config/Darwin/karabiner";
    link = (builtins.getEnv "HOME") + "/.config/karabiner";
  }];
}
