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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database = {
      url = "github:nix-community/nix-index-database/e76ff2df6bfd2abe06abd8e7b9f217df941c1b07";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # neovim-nightly-overlay = {
    #   url = "github:nix-community/neovim-nightly-overlay";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    inputs@{ nixpkgs
    , nixpkgs-unstable
    , nix-index-database
    , nixos-wsl
    , nix-darwin
    , home-manager
    , flake-utils
    , nix-on-droid
    , ...
    }: with flake-utils.lib; eachDefaultSystem (system:
    let
      log = v: builtins.trace v v;
      overlays = [
        # inputs.neovim-nightly-overlay.overlay
      ];
      pkgs = builtins.trace system (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        # overlays = overlays;
      });
      unstablePkgs = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkDocker = {}: rec {
        frpc = import ./docker/frpc.nix {
          inherit system;
          inherit pkgs;
        };
        frpc-drive = import ./docker/frpc-drive.nix {
          inherit system;
          inherit pkgs;
        };
      };

      mkHomeExtraSpecialArgs =
        { useSecret ? true
        , useProxy ? false
        , useMirrorDrive ? false # useMirrorDrive is a boolean to config if copy remote config from google drive by rclone instead of Google drive stream
        , isMobile ? false
        }: { inherit useSecret useProxy useMirrorDrive isMobile; };

      mkHome =
        { modules ? [ ], extraSpecialArgs ? (mkHomeExtraSpecialArgs { }) }: home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = log (builtins.filter (el: el != "") modules);

          # Nix has dynamic scope, extraSpecialArgs will be passed to evalModules as the scope of funcitons,
          #   which means those functions can access `useSecret` directly instead of `specialArgs.useSecret`
          #   TL;DR: https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/default.nix#L26
          extraSpecialArgs = {
            inherit system unstablePkgs;
          } // extraSpecialArgs;
        };

      mkNixOS = { modules ? [ ], imports ? [ ], extraSpecialArgs ? (mkHomeExtraSpecialArgs { }) }: nixpkgs.lib.nixosSystem {
        inherit system pkgs;

        modules = log (builtins.filter (el: el != "") (modules ++ [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit system unstablePkgs;
            } // extraSpecialArgs;

            home-manager.users.root.imports = log (builtins.filter (el: el != "") imports);
          }
        ]));

      };
    in
    {
      packages = {
        home-manager = home-manager.defaultPackage.${system};
        nix-darwin = nix-darwin.packages.${system}.default;
        nix-on-droid = nix-on-droid.packages.${system};

        homeConfigurations = {
          vpn-server = mkHome {
            modules = [
              ./home/vpn-server.nix
            ];
          };
          # cn drive
          drive-server = mkHome {
            modules = [
              ./home/drive-server.nix
            ];
          };
          # m3 || wsl || ec2
          ide = mkHome {
            modules = [
              ./home/ide.nix
              nix-index-database.hmModules.nix-index
            ];
          };
          # c02fk4mjmd6m
          ide-mirror = mkHome {
            modules = [
              ./home/ide.nix
            ];
            extraSpecialArgs = mkHomeExtraSpecialArgs {
              useMirrorDrive = true;
            };
          };
          # cn ec2
          ide-cn = mkHome {
            modules = [
              ./home/ide.nix
            ];
            extraSpecialArgs = mkHomeExtraSpecialArgs {
              useProxy = true;
            };
          };
          # mobile
          ide-mobile = mkHome {
            modules = [
              ./home/ide.nix
            ];
            extraSpecialArgs = mkHomeExtraSpecialArgs {
              isMobile = true;
              useMirrorDrive = true;
            };
          };

          # clean all packages & generated files
          eject = mkHome {
            modules = [
              ./home/eject.nix
            ];
          };
        };

        darwinConfigurations = {
          "darwin" = nix-darwin.lib.darwinSystem {
            inherit system pkgs;

            modules = log [
              ./systems/darwin.nix
            ];

            specialArgs = { inherit inputs; };
          };
        };

        nixosConfigurations = {
          wsl = mkNixOS
            {
              modules = [
                nixos-wsl.nixosModules.default
                ./systems/nixos-wsl.nix
              ];
              imports = [
                ./home/ide.nix
                nix-index-database.hmModules.nix-index
              ];
            };
        };

        nixOnDroidConfigurations = {
          "default" = nix-on-droid.lib.nixOnDroidConfiguration {
            inherit system pkgs;

            modules = [
              ./systems/aarch64-linux.nix
            ];
          };
        };

        docker = mkDocker { };
      };
    });
}
