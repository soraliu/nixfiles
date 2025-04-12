{ pkgs ? import <nixpkgs> { }, ... }: pkgs.dockerTools.buildNixShellImage {
  drv = pkgs.coreutils;
  name = "coreutils";
  tag = "latest";
}
