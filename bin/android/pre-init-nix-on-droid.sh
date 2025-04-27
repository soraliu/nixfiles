#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/release-24.11.tar.gz
#! nix-shell -p bash busybox git curl

nix-on-droid switch --show-trace --flake github:soraliu/nixfiles#defaults

nix run github:soraliu/nixfiles#home-manager -- switch --show-trace --impure --flake github:soraliu/nixfiles#ide -b backup
