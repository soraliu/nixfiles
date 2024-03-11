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
      url = "github:lnl7/nix-darwin/550340062c16d7ef8c2cc20a3d2b97bcd3c6b6f6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, flake-utils, ... }:
    let
      log = v : builtins.trace v v;

      mkHome = { system, user, useSecret ? false }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};

        modules = builtins.filter (el: el != "") [
          ./programs/common
          (if builtins.pathExists ./programs/${system} then ./programs/${system} else "")
          ./users/${system}/${user}
        ];

        # Nix has dynamic scope, extraSpecialArgs will be passed to evalModules as the scope of funcitons,
        #   which means those functions can access `useSecret` directly instead of `specialArgs.useSecret`
        #   TL;DR: https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/default.nix#L26
        extraSpecialArgs = {
          inherit useSecret;
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };

      mkDarwin = { system, host }: nix-darwin.lib.darwinSystem {
        pkgs = nixpkgs.legacyPackages."${system}";
        system = system;

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

      homeConfigurations."user" = mkHome {
        system = "x86_64-darwin";
        user = "user";
        useSecret = true;
      };

      darwinConfigurations."c02fk4mjmd6m" = mkDarwin {
        system = "x86_64-darwin";
        host = "c02fk4mjmd6m";
      };

    } // (with flake-utils.lib; (eachDefaultSystem (
      system: {
        packages = {
          home-manager = home-manager.defaultPackage.${system};
          nix-darwin = nix-darwin.packages.${system}.default;
        };
      }
    )));
}
