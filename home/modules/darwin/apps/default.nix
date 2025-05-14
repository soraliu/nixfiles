{ unstablePkgs, ... }: {
  imports = [
    ./clashx
    ./iterm2
    ./karabiner
    ./raycast
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
