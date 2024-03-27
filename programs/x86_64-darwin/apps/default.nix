{ unstablePkgs, ... }: {
  imports = [
    ../../common/fs/rclone

    ./raycast
    ./hiddify
  ];

  home.packages = with unstablePkgs; [
    postman
  ];

  home.sessionVariables = { };
}
