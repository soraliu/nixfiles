{
  description = "Home Manager configuration";

  nixConfig = {
    # substituers will be appended to the default substituters when fetching packages
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, ... }:
    let
      mkHome = { system, user }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = builtins.filter (el: el != "") [
          ./programs/common
          (if builtins.pathExists ./programs/${system} then ./programs/${system} else "")
          ./users/${system}/${user}
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };

      mkDarwinHost = { system, host }: nix-darwin.lib.darwinSystem {
        pkgs = nixpkgs.legacyPackages."${system}";

        modules = [
          ./hosts/${system}/${host}
        ];

        specialArgs = { inherit inputs; };
      };
    in {
      homeConfigurations."root" = mkHome {
        system = "x86_64-linux";
        user = "root";
      };

      homeConfigurations."c02fk4mjmd6m" = mkHome {
        system = "x86_64-darwin";
        user = "user";
      };

      darwinConfigurations."c02fk4mjmd6m" = mkDarwinHost {
        system = "x86_64-darwin";
        host = "c02fk4mjmd6m";
      };
    };
}
