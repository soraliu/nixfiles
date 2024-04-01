{ pkgs, pname, version, src, ... }: with pkgs; stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version src;

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    set -x

    runHook preInstall

    ls -al

    mkdir -p $out/Applications/
    cp -rf ./*.app $out/Applications/

    runHook postInstall
  '';
})
