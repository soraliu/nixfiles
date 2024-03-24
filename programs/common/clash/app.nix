# { pkgs ? import <nixpkgs> {} }: let
let
  pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "clash-premium";
  version = "0.0.1";
  system = builtins.currentSystem;

  src = ./.;

  buildInputs = with pkgs; [ wget ];
  skipInstallPhase = true;

  buildPhase = ''
    mkdir -p $out/bin
    wget=${pkgs.wget}/bin/wget

    case "${builtins.currentSystem}" in
      "x86_64-linux" | "x86_64-darwin")
        $wget https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release/clashpremium-linux-amd64 -O $out/bin/clash
        ;;
      *)
        # Unsupported Linux distribution
        exit 1
        ;;
    esac

    $wget https://github.com/soraliu/clash_singbox-tools/raw/main/Clash-dashboard/metacubexd.tar.gz -O $out/metacubexd.tar.gz
    mkdir -p $out/ui
    tar -zx $out/metacubexd.tar.gz -C $out/ui/
  '';
}
