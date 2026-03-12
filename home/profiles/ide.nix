{ system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = builtins.filter (el: el != "") [
    ../core/base.nix

    ../modules/sys

    ../modules/ai/huggingface.nix
    ../modules/ai/shell-gpt
    ../modules/ai/cc

    ../modules/ide

    ../modules/lang/nodejs.nix
    ../modules/lang/python.nix
    ../modules/lang/android.nix
    ../modules/lang/go.nix
    ../modules/lang/lua.nix
    ../modules/lang/rust.nix
    ../modules/lang/db.nix

    ../modules/network/clash-meta
    ../modules/network/nebula

    ../modules/cloud

    (if isDarwin then ../modules/darwin else "")
  ];
}
