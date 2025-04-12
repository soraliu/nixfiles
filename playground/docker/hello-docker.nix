{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }, ... }: pkgs.dockerTools.buildImage {
  name = "hello";
  tag = "latest";
  created = "now";

  copyToRoot = with pkgs.dockerTools; [
    usrBinEnv
    binSh
  ];

  runAsRoot = ''
    echo "hello world"
  '';

  config = {
    Cmd = [
      "/bin/sh"
    ];
  };
}
