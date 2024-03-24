# { pkgs ? import <nixpkgs> {} }: let
let
  pkgs = import <nixpkgs> {};
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "clash-premium";
  version = "0.0.1";
  system = builtins.currentSystem;

  srcs = with pkgs; [
    (fetchurl {
      url = "https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release";
      hash = "sha256-lZ+rqZLEoTkx6On/7uO8X6nL+7l8CyPo0jjIL46zVCA=";
    })
    (fetchurl {
      url = "https://github.com/soraliu/clash_singbox-tools/raw/main/Clash-dashboard";
      hash = "sha256-CtLinzLs9fQu+2KoACYaMsUA7nulag8wZ72CyoGbpq4=";
    })
  ];
  # sourceRoot = ".";

  buildInputs = with pkgs; [ tree ];
  skipBuildPhase = true;

  unpackPhase = ''
    runHook preUnpack

    for _src in $srcs; do
      cp "$_src" $(stripHash "$_src")
    done

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    case "${builtins.currentSystem}" in
      "x86_64-linux" | "x86_64-darwin")
        cp ClashPremium-release/clashpremium-linux-amd64 $out/bin/clash
        ;;
      *)
        # Unsupported Linux distribution
        exit 1
        ;;
    esac

    mkdir -p $out/ui
    tar -zx Clash-dashboard/metacubexd.tar.gz -C $out/ui/

    runHook postInstall
  '';
}
