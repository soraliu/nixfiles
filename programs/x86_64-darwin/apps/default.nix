{ unstablePkgs, useProxy, ... }: {
  imports = [
    ./clashx
  ] ++ (if useProxy then [
    ../../common/fs/rclone
    ./todoist
    ./raycast
    ./iterm2
    ./sublime
    ./wireshark
    ./karabiner
    ./snipaste
  ] else []);

  home = {
    packages = with unstablePkgs; [
      postman
      dbeaver
      obsidian
      caffeine
    ];
  };
}
