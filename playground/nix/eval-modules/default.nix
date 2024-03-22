let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  # NOTE: https://github.com/NixOS/nixpkgs/blob/master/lib/modules.nix#L73
  modules = lib.evalModules {
    modules = [
      ./module-a.nix
    ];
    specialArgs = {
      txt = "This a txt";
    };
  };
in pkgs.stdenv.mkDerivation (finalAttrs: {
  # NOTE: https://nix.dev/manual/nix/2.19/language/builtins#builtins-toJSON
  name = builtins.trace modules builtins.trace (builtins.toJSON modules.config) "eval-module";

  src = ./.;

  buildPhase = ''
    mkdir -p $out;
  '';
})
