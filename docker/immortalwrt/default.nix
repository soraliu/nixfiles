{ pkgs ? import <nixpkgs> { }, ... }:
let
  # Pre-built immortalwrt base image tar file path
  # Need to run first: just build-immortalwrt-base 
  immortalwrtBaseImage = /tmp/immortalwrt-base.tar;

  pathToClashConfig = "etc/nikki/profiles/config.yaml";
in
pkgs.dockerTools.buildImage {
  name = "immortalwrt";
  tag = "latest";
  created = "now";

  fromImage = immortalwrtBaseImage;

  copyToRoot = [
    (import ../../pkgs/sops/decrypt.nix {
      inherit pkgs;
      files = [{
        from = "secrets/.config/clash/config-whitelist.enc.yaml";
        to = pathToClashConfig;
      }];
    })
  ];

  config = {
    Cmd = [ "/sbin/init" ];
  };
}
