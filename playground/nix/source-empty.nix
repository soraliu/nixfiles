let
  pkgs = import <nixpkgs> { };
in pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "source-empty";
  src = pkgs.runCommandNoCC "empty" {} "mkdir $out";
  buildPhase = ''
    mkdir -p $out;

    ls -al $src;
  '';
  dontInstall = true;
})

