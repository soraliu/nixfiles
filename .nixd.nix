# .nixd.nix
{
  "$schema" = "https://raw.githubusercontent.com/nix-community/nixd/main/nixd/docs/nixd-schema.json";
  eval = {
    # Example target for writing a package.
    target = {
      args = [ "--expr" "with import <nixpkgs> { }; callPackage ./flake.nix { }" ];
      installable = "";
    };
    # Force thunks
    depth = 10;
  };
  formatting.command = "nixpkgs-fmt";
  options = {
    enable = true;
    target = {
      args = [ ];
      # Example installable for flake-parts, nixos, and home-manager

      # flake-parts
      # installable = "/flakeref#debug.options";

      # nixOS configuration
      # installable = "/flakeref#nixosConfigurations.<adrastea>.options";

      # home-manager configuration
      installable = "/flakeref#homeConfigurations.root.options";
    };
  };
}

