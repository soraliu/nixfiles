let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

in pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "source-paths";

  src = builtins.path {
    path = ../.;
    filter = name: type: let
      baseName = builtins.trace name baseNameOf name;
    in
      !(type == "directory" && baseName == "basis") &&
      !(builtins.match ".*\.nix" baseName != null);
  };

  nativeBuildInputs = with pkgs; [ tree ];
  buildPhase = ''
    mkdir -p $out;

    tree .
  '';
  dontInstall = true;
})

