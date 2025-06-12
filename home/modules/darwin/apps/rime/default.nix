{ pkgs, ... }: with pkgs; {
  config = {
    programs = {
      linker.links = [
        {
          source = "gdrive:Sync/Config/Darwin/rime";
          link = (builtins.getEnv "HOME") + "/Library/Rime";
        }
      ];
    };
  };
}
