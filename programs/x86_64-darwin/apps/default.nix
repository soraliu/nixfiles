{ unstablePkgs, ... }: {
  imports = [
    ../../common/fs/rclone

    ./todoist
    ./raycast
    ./hiddify
    ./sublime
    ./wireshark
    ./karabiner
    ./snipaste
  ];

  home = {
    packages = with unstablePkgs; [
      postman
      iterm2
      dbeaver
      obsidian
      caffeine
    ];
  };

  programs = {
    rclone = {
      syncPaths = [{
        remote = "gdrive:Sync/Config/Darwin/com.googlecode.iterm2";
      }];
    };
  };
}
