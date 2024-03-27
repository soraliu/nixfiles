{ unstablePkgs, ... }: {
  imports = [
    ../../common/fs/rclone

    ./raycast
    ./hiddify
    ./todoist
  ];

  home.packages = with unstablePkgs; [
    postman
    iterm2
  ];

  home.sessionVariables = { };
}
