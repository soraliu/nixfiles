{ system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = builtins.filter (el: el != "") ([
    ../core/base.nix

    ../modules/sys/fs
    ../modules/sys/network
    ../modules/sys/doc
    ../modules/sys/json
    ../modules/sys/container
    ../modules/sys/pw
    ../modules/sys/shell

    ../modules/ai/openclaw
    ../modules/ai/huggingface
    ../modules/ai/cc

    ../modules/ide/git
    ../modules/ide/zsh
    ../modules/ide/neovim
    ../modules/ide/zellij
    ../modules/ide/search
    ../modules/ide/copilot.nix

    ../modules/lang/nodejs.nix
    ../modules/lang/python.nix
    ../modules/lang/go.nix
    ../modules/lang/db.nix

    ../modules/network/nebula

    ../modules/cloud/k8s

    (if isDarwin then ../modules/darwin/base.nix else "")
    (if isDarwin then ../modules/darwin/apps/rime else "")
    (if isDarwin then ../modules/darwin/apps/iterm2 else "")
  ]);
}
