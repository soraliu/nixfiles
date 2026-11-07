{ pkgs ? import <nixpkgs> { }, ... }:
let
  # Pre-built immortalwrt base image tar file path
  # Need to run first: just build-immortalwrt-base 
  immortalwrtBaseImage = /tmp/immortalwrt-base.tar;

  # clash 配置在本镜像构建时烘进 etc/nikki/profiles/config.yaml，运行时由
  # nikki 以 profile=file:config.yaml 加载。改 secrets/.config/clash/config-whitelist.enc.yaml
  # 后镜像不会自动更新，必须二选一：
  #   1) 重建并替换容器（会短暂中断全屋网络）：
  #      docker/ 下 `just build image="immortalwrt"` → `docker save` → docker 主机 `docker load`
  #      → docker rm -f immortalwrt → 按原参数 docker run --network macnet --ip 192.168.31.2
  #        --mac-address 02:42:c0:a8:1f:02 --privileged ... /sbin/init
  #   2) 临时热改（保持运行时与声明一致，重建镜像后自然对齐）：
  #      docker cp config.yaml immortalwrt:/etc/nikki/profiles/config.yaml
  #      docker exec immortalwrt /etc/init.d/nikki restart

  pathToClashConfig = "etc/nikki/profiles/config.yaml";
in
pkgs.dockerTools.buildImage {
  name = "immortalwrt";
  tag = "latest";
  created = "now";

  fromImage = immortalwrtBaseImage;

  copyToRoot = [
    (import ../pkgs/sops/decrypt.nix {
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
