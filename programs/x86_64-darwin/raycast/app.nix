{ lib, stdenvNoCC, fetchurl, undmg }:
stdenvNoCC.mkDerivation (finalAttrs: rec {
  pname = "raycast";
  version = "1.70.0";

  src = fetchurl {
    name = "Raycast-${version}.dmg";
    url = "https://raycast-releases-9b5ab5b505ea.herokuapp.com/releases/${version}/download";
    hash = "sha256-+8P8bTD4I4Se/Ii6/oHiqzqgqkrf4QNQ9RL/l9MRuO0=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = "Raycast.app";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/Raycast.app
    cp -R . $out/Applications/Raycast.app

    runHook postInstall
  '';
})
