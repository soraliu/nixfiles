{ unstablePkgs, ... }: {
  imports = [
    ./clashx
    ./iterm2
    ./raycast
    ./snipaste
    ./sublime
  ];

  home = {
    packages = with unstablePkgs; [
      postman
      dbeaver
      obsidian
    ];
  };
}
