{ pkgs, lib, txt, ... }: {
  options.evalModule = {
    # NOTE: https://github.com/NixOS/nixpkgs/blob/master/lib/options.nix#L66
    enable = lib.mkOption {
      # NOTE: https://github.com/NixOS/nixpkgs/blob/master/lib/types.nix#L218
      type = lib.types.bool;
      default = true;
      example = false;
      description = lib.mdDoc "Whether to enable.";
    };
    content = lib.mkOption {
      type = lib.types.str;
      default = txt;
      description = lib.mdDoc "Content text.";
    };
  };
}
