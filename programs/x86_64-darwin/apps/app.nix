{ pkgs, pname, version, src, ... }: with pkgs; stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version src;

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/
    cp -rf ./*.app $out/Applications/

    runHook postInstall
  '';
})
