{ unstablePkgs, ... }: {
  imports = [
    ./clashx
    ./iterm2
    ./karabiner
    ./raycast
    ./snipaste
    ./sublime
  ];

  home = {
    packages = with unstablePkgs; [
      postman
      dbeaver-bin
      obsidian
    ];
  };
}
