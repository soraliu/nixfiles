{ pkgs ? import <nixpkgs> { }, variant ? "frpc", ... }:
let
  pathToFrpcConfig = "root/.config/frp/frpc.toml";
  
  variantConfig = if variant == "frpc-drive" then {
    imageName = "frpc-drive";
    secretFile = "secrets/.config/frp/frpc-drive.enc.toml";
  } else {
    imageName = "frpc";
    secretFile = "secrets/.config/frp/frpc.enc.toml";
  };
in
pkgs.dockerTools.buildImage {
  name = variantConfig.imageName;
  tag = "latest";
  created = "now";

  fromImage = pkgs.dockerTools.pullImage {
    imageName = "library/alpine";
    imageDigest = "sha256:1c4eef651f65e2f7daee7ee785882ac164b02b78fb74503052a26dc061c90474";
    finalImageName = "alpine";
    finalImageTag = "3.21.3";
    sha256 = "sha256-BLd0y9w1FIBJO5o4Nu5Wuv9dtGhgvh+gysULwnR9lOo=";
  };

  copyToRoot = with pkgs; [
    frp
    (
      import ../pkgs/sops/decrypt.nix {
        inherit pkgs;
        files = [{
          from = variantConfig.secretFile;
          to = pathToFrpcConfig;
        }];
      }
    )
  ];

  config = {
    Cmd = [
      "${pkgs.frp}/bin/frpc"
      "-c"
      "/${pathToFrpcConfig}"
    ];
    WorkingDir = "/root";
  };
}
