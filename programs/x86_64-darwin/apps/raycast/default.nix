{ pkgs, ... }: with pkgs; {
  imports = [
    ../../../common/fs/sops
  ];

  config = {
    programs = {
      sops.decryptFiles = [{
        from = "secrets/.config/raycast/database_key.enc";
        to = ".config/raycast/database_key";
      }];

      linker.links = [
        {
          source = "gdrive:Sync/Config/Darwin/com.raycast.macos";
          link = (builtins.getEnv "HOME") + "/Library/Application Support/com.raycast.macos";
        }
        {
          source = "gdrive:Sync/Config/Darwin/.config/raycast";
          link = (builtins.getEnv "HOME") + "/.config/raycast";
        }
      ];
    };
  };
}
