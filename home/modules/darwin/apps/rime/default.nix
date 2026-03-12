{ pkgs, config, ... }: with pkgs; {
  config = {
    programs = {
      linker.links = [
        {
          source = "gdrive:Sync/Config/Darwin/rime";
          link = config.home.homeDirectory + "/Library/Rime";
        }
      ];
    };
  };
}
