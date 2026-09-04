{ config, lib, ... }:
let
  target = "${config.home.homeDirectory}/.config/ai/imagegen.auth.json";
  source = config.home.file.".config/ai/imagegen.auth.json".source;
in {
  config = {
    programs.sops.decryptFiles = [{
      from = "secrets/.config/ai/imagegen.auth.enc.json";
      to = ".config/ai/imagegen.auth.json";
    }];

    home.file.".config/ai/imagegen.auth.json".force = true;

    home.activation.secureImagegenAuth = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      temporary="${target}.tmp"
      install -m 600 "${source}" "$temporary"
      mv -f "$temporary" "${target}"
    '';
  };
}
