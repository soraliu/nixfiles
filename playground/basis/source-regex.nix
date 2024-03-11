let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # NOTE: https://github.com/NixOS/nixpkgs/blob/master/lib/sources.nix#L119
  source = lib.sourceByRegex ./. [
    ".*\.md$"
  ];
in pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "source-regex";
  src = source;
  nativeBuildInputs = with pkgs; [ tree ];
  buildPhase = ''
    mkdir -p $out;

    tree .
  '';
  dontInstall = true;
})

