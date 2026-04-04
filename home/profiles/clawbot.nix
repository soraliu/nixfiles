{ system, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  imports = builtins.filter (el: el != "") ([
    ../core/base.nix

    ../modules/sys/fs
    ../modules/sys/network
    ../modules/sys/json
    ../modules/sys/container
    ../modules/sys/shell

    ../modules/ai/openclaw
    ../modules/ai/cc

    ../modules/ide/git
    ../modules/ide/zsh
    ../modules/ide/neovim
    ../modules/ide/zellij
    ../modules/ide/search/fzf
    ../modules/ide/search/ripgrep
    ../modules/ide/copilot.nix

    ../modules/lang/nodejs.nix
    ../modules/lang/python.nix
    ../modules/lang/go.nix
    ../modules/lang/db.nix

    # Paperclip pm2 service module
    ../modules/sys/pm2/paperclip.nix

    (if isDarwin then ../modules/darwin/base.nix else "")
    (if isDarwin then ../modules/darwin/apps/rime else "")
    (if isDarwin then ../modules/darwin/apps/iterm2 else "")
  ]);
}
