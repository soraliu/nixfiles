{ pkgs, app, version, src, ... }: with pkgs; let
  appName = "${app}.app";
in stdenvNoCC.mkDerivation (finalAttrs: {
  inherit version src;
  pname = app;

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = appName;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/${appName}
    cp -R . $out/Applications/${appName}

    runHook postInstall
  '';
})
