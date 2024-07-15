{ unstablePkgs, ... }: {
  imports = [
    ./iterm2
    ./karabiner
    ./raycast
    ./snipaste
  ];

  home = {
    packages = with unstablePkgs; [
      postman
      dbeaver
      obsidian
      caffeine
    ];
  };
}
