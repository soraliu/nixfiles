let
  pkgs = import <nixpkgs> { };

  # NOTE: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders/default.nix
  home = pkgs.runCommandNoCC "fake-home" {} ''
    mkdir -p $out
  '';
in pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "run-command";
  src = home;
  buildPhase = ''
    pwd
    ls -al
    mkdir -p $out;
  '';
  dontInstall = true;
})

