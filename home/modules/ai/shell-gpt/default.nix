{ unstablePkgs, lib, config, ... }: {
  config = {
    home.packages = with unstablePkgs; [
      shell-gpt
    ];

    home.activation.copyShellGPTFile = let
      src = ./sgptrc;
      target = "${config.home.homeDirectory}/.config/shell_gpt/.sgptrc";
    in lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $(dirname ${target})
      cp ${src} ${target}
      chmod +w ${target}
    '';
  };
}
