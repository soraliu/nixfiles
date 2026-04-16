{ system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = builtins.filter (el: el != "") [
    ../core/base.nix

    ../modules/sys/fs
    ../modules/sys/network
    ../modules/sys/doc
    ../modules/sys/json
    ../modules/sys/container
    ../modules/sys/pw
    ../modules/sys/shell

    ../modules/ai/huggingface
    ../modules/ai/shell-gpt
    ../modules/ai/cc
    ../modules/ai/codex
    ../modules/ai/context7

    ../modules/ide/git
    ../modules/ide/zsh
    ../modules/ide/neovim
    ../modules/ide/zellij
    ../modules/ide/search
    ../modules/ide/copilot.nix
    ../modules/ide/iac.nix

    ../modules/lang/nodejs.nix
    ../modules/lang/python.nix
    ../modules/lang/android.nix
    ../modules/lang/go.nix
    ../modules/lang/lua.nix
    ../modules/lang/rust.nix
    ../modules/lang/db.nix
    ../modules/lang/just.nix
    ../modules/lang/sol.nix

    ../modules/network/caddy
    ../modules/network/clash-meta
    ../modules/network/nebula

    ../modules/cloud/k8s

    (if isDarwin then ../modules/darwin/base.nix else "")
    (if isDarwin then ../modules/darwin/apps else "")
  ];
}
