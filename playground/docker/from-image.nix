{ pkgs ? import <nixpkgs> { }, ... }: pkgs.dockerTools.buildImage {
  name = "nix-nginx";
  tag = "latest";

  fromImage = pkgs.dockerTools.pullImage {
    imageName = "library/alpine";
    imageDigest = "sha256:1c4eef651f65e2f7daee7ee785882ac164b02b78fb74503052a26dc061c90474";
    finalImageName = "alpine";
    finalImageTag = "3.21.3";
    sha256 = "sha256-BLd0y9w1FIBJO5o4Nu5Wuv9dtGhgvh+gysULwnR9lOo=";
  };
  copyToRoot = with pkgs; [
    nginx
    (writeTextFile {
      name = "index.html";
      text = "<h1>Hello NixOS Docker!</h1>";
      destination = "${pkgs.nginx}/html/index.html";
    })
    (
      import ../../pkgs/sops/decrypt.nix {
        inherit pkgs;
        files = [{
          from = "secrets/.npmrc.enc";
          to = "root/.npmrc";
        }];
      }
    )
  ];
  runAsRoot = ''
    #!${pkgs.runtimeShell}
    mkdir -p /var/log/nginx /var/cache/nginx
  '';
  config = {
    Cmd = [
      "${pkgs.nginx}/bin/nginx"
      "-g"
      "daemon off; error_log /dev/stderr; pid /dev/null;"
    ];
    ExposedPorts = { "80/tcp" = { }; };
    WorkingDir = "/root";
  };
}
