{ unstablePkgs, ... }: {
  imports = [
    ./raycast
    ./hiddify
  ];

  home.packages = with unstablePkgs; [
    postman
  ];

  home.sessionVariables = { };
}
