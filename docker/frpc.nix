{ pkgs ? import <nixpkgs> { }, ... }: pkgs.dockerTools.buildImage {
  name = "frpc";
  tag = "latest";
  created = "now";

  copyToRoot = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    (fakeNss.override {
      extraGroupLines = [
        "nogroup:x:65533:"
      ];
    })

  ] ++ (with pkgs; [
    coreutils
    shadow
    ps
    nginx
    (writeTextFile {
      name = "index.html";
      text = "<h1>Hello NixOS Docker!</h1>";
      destination = "${pkgs.nginx}/html/index.html";
    })
  ]);

  runAsRoot = ''
    ${pkgs.coreutils}/bin/mkdir -p /var/log/nginx /var/cache/nginx
    ${pkgs.coreutils}/bin/chmod 755 /var/log/nginx
  '';

  config = {
    Cmd = [
      "${pkgs.nginx}/bin/nginx"
      "-g"
      "daemon off; error_log /dev/stderr; pid /dev/null;"
    ];
    ExposedPorts = { "80/tcp" = { }; };
  };
}
