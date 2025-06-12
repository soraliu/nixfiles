{ unstablePkgs, ... }: {
  imports = [
    ./clashx
    ./iterm2
    ./karabiner
    ./raycast
    ./sublime
    ./rime
  ];

  home = {
    packages = with unstablePkgs; [
      postman
      dbeaver-bin
      obsidian
    ];
  };
}
