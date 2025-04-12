{ pkgs ? import <nixpkgs> { }, ... }: pkgs.dockerTools.buildImage {
  name = "nix-nginx";
  tag = "latest";

  # fromImage = "library/alpine";
  # fromImageName = null;
  # fromImageTag = "3.21.3";
  fromImage = pkgs.dockerTools.pullImage {
    imageName = "library/alpine";
    imageDigest = "sha256:1c4eef651f65e2f7daee7ee785882ac164b02b78fb74503052a26dc061c90474";
    finalImageName = "alpine";
    finalImageTag = "3.21.3";
    sha256 = "sha256-BLd0y9w1FIBJO5o4Nu5Wuv9dtGhgvh+gysULwnR9lOo=";
  };
  runAsRoot = ''
    #!${pkgs.runtimeShell}
    /sbin/apk update -y
    /sbin/apk add --no-cache nginx
  '';
  config = {
    Cmd = [ "nginx" "-g" "daemon off;" ];
    # Cmd = [ "/bin/sh" ];
  };
}
