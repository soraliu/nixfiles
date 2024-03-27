let
  pkgs = import <nixpkgs> { };
in
# NOTE: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders/default.nix
pkgs.runCommandNoCC "fake-home" {
  buildInputs = with pkgs; [hello];
} ''
  mkdir -p $out

  hello

  echo out $out
  echo pwd $(pwd)
''
