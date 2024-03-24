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
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database = {
      url = "github:nix-community/nix-index-database/e76ff2df6bfd2abe06abd8e7b9f217df941c1b07";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  outputs = inputs@{
    nixpkgs,
    nixpkgs-unstable,
    nix-index-database,
    nix-darwin,
    home-manager,
    flake-utils,
    ...
  }: with flake-utils.lib; eachDefaultSystem (system: let
    log = v : builtins.trace v v;

    mkHome = {
      user,
      extraModules ? [],
      useCommon ? true,
      useSecret ? true,
      useIndex ? true,
      useProxy ? false,
    }: home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."${system}";

      modules = builtins.filter (el: el != "") [
        (if useIndex then nix-index-database.hmModules.nix-index else "")
        (if useCommon then ./programs/common else "")
        (if builtins.pathExists ./programs/${system} then ./programs/${system} else "")
        (if builtins.pathExists ./users/${system}/${user} then ./users/${system}/${user} else ./users)
      ] ++ extraModules;

      # Nix has dynamic scope, extraSpecialArgs will be passed to evalModules as the scope of funcitons,
      #   which means those functions can access `useSecret` directly instead of `specialArgs.useSecret`
      #   TL;DR: https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/default.nix#L26
      extraSpecialArgs = {
        inherit useSecret useProxy useIndex;
        useGlobalPkgs = true;
        useUserPackages = true;
        unstablePkgs = nixpkgs-unstable.legacyPackages."${system}";
      };
    };

    mkDarwin = { system, host }: nix-darwin.lib.darwinSystem {
      pkgs = nixpkgs.legacyPackages.${system};
      system = system;

      modules = [
        ./hosts/${system}/${host}
      ];

      specialArgs = { inherit inputs; };
    };
  in {
    packages = {
      home-manager = home-manager.defaultPackage.${system};
      nix-darwin = nix-darwin.packages.${system}.default;

      homeConfigurations = {
        vpn-server = mkHome {
          user = "vpn-server";
          useCommon = false;
          useSecret = false;
          useIndex = false;
          extraModules = [
            ./programs/common/fs
            ./programs/common/ide
          ];
        };
        # c02fk4mjmd6m
        user = mkHome {
          user = "user";
        };
        # C02CN4BGML7H
        soraliu = mkHome {};
        # wsl
        sora = mkHome {};
        # linux with proxy
        ide.root = mkHome {
          user = "root";
          useProxy = true;
        };
        # linux without proxy
        root = mkHome {
          user = "root";
        };
      };

      darwinConfigurations = {
        # work darwin
        "c02fk4mjmd6m" = mkDarwin {
          system = "x86_64-darwin";
          host = "c02fk4mjmd6m";
        };
      };
    };
  });
}
