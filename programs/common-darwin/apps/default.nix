{ unstablePkgs, ... }: {
  imports = [
    ./iterm2
    ./raycast
    ./snipaste
  ];

  home = {
    packages = with unstablePkgs; [
      postman
      dbeaver
      obsidian
    ];
  };
}
