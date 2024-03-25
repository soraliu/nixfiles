{ stdenvNoCC, fetchurl, undmg, ... }:
stdenvNoCC.mkDerivation (finalAttrs: rec {
  pname = "hiddify";
  version = "1.0.0";

  src = fetchurl {
    name = "Hiddify-${version}.dmg";
    url = "https://github.com/hiddify/hiddify-next/releases/download/v${version}/Hiddify-MacOS.dmg";
    hash = "sha256-Nd+tm9Ik4Fguag0qDdcn+nnDgk+q1xY3HeY64Cv1zIc=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = "Hiddify.app";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/Hiddify.app
    cp -R . $out/Applications/Hiddify.app

    runHook postInstall
  '';
})
