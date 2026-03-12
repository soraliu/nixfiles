{ pkgs, config, ... }: with pkgs; {
  config = {
    programs = {
      sops.decryptFiles = [{
        from = "secrets/.config/raycast/database_key.enc";
        to = ".config/raycast_database_key";
      }];

      linker.links = [
        {
          source = "gdrive:Sync/Config/Darwin/com.raycast.macos";
          link = config.home.homeDirectory + "/Library/Application Support/com.raycast.macos";
        }
        {
          source = "gdrive:Sync/Config/Darwin/.config/raycast";
          link = config.home.homeDirectory + "/.config/raycast";
        }
      ];
    };
  };
}
