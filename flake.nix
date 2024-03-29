{
  description = "Home Manager configuration";

  nixConfig = {
    # override the default substituters
    substituters = [
      # cache mirror located in China
      # status: https://mirror.sjtu.edu.cn/
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
      # status: https://mirrors.ustc.edu.cn/status/
      # "https://mirrors.ustc.edu.cn/nix-channels/store"

      "https://cache.nixos.org"

      # nix community's cache server
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      # nix community's cache server public key
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
      user ? "",
      useSecret ? true,
      useIndex ? true,
      useProxy ? false,
      useCommon ? true,
      extraModules ? [],
    }: home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      modules = log (builtins.filter (el: el != "") [
        ./programs/common

        (if useIndex then nix-index-database.hmModules.nix-index else "")
        (if builtins.pathExists ./programs/${system} then ./programs/${system} else "")
        (if (user != "" && builtins.pathExists ./users/${system}/${user}) then ./users/${system}/${user} else if builtins.pathExists ./users/${system} then ./users/${system} else ./users)
      ] ++ extraModules);

      # Nix has dynamic scope, extraSpecialArgs will be passed to evalModules as the scope of funcitons,
      #   which means those functions can access `useSecret` directly instead of `specialArgs.useSecret`
      #   TL;DR: https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/default.nix#L26
      extraSpecialArgs = {
        inherit useCommon useSecret useProxy useIndex;

        unstablePkgs = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };

    mkDarwin = {
      system,
      host,
    }: nix-darwin.lib.darwinSystem {
      inherit system;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

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
          useSecret = true;
          useIndex = false;
          useProxy = false;
          useCommon = false;
          extraModules = [
            ./programs/common/ide/git
            ./programs/common/network
          ];
        };
        # c02fk4mjmd6m || wsl || ec2
        ide = mkHome {
          useSecret = true;
          useIndex = true;
          useProxy = false;
          useCommon = true;
        };
        # cn ec2
        ide-cn = mkHome {
          useSecret = true;
          useIndex = true;
          useProxy = true;
          useCommon = true;
        };
      };

      darwinConfigurations = {
        "c02fk4mjmd6m" = mkDarwin {
          system = "x86_64-darwin";
          host = "c02fk4mjmd6m";
        };
      };
    };
  });
}
