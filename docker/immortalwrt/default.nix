{ pkgs ? import <nixpkgs> { }, ... }:
let
  # 预构建的 immortalwrt 基础镜像 tar 文件路径
  # 需要先运行: just build-immortalwrt-base 
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
