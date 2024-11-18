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
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-23.11";
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
    , nix-darwin
    , home-manager
    , flake-utils
    , nix-on-droid
    , ...
    }: with flake-utils.lib; eachDefaultSystem (system:
    let
      log = v: builtins.trace v v;
      systemMaps = {
        "x86_64-darwin" = "common-darwin";
        "aarch64-darwin" = "common-darwin";
      };
      overlays = [
        # inputs.neovim-nightly-overlay.overlay
      ];

      mkHome = { modules, extraSpecialArgs ? { } }: home-manager.lib.homeManagerConfiguration {
        pkgs = builtins.trace system (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          # overlays = overlays;
        });

        modules = log (builtins.filter (el: el != "") modules ++ [
          ./programs/common/pkg-manager/home-manager
        ]);

        # Nix has dynamic scope, extraSpecialArgs will be passed to evalModules as the scope of funcitons,
        #   which means those functions can access `useSecret` directly instead of `specialArgs.useSecret`
        #   TL;DR: https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/default.nix#L26
        extraSpecialArgs = {
          unstablePkgs = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        } // extraSpecialArgs;
      };


      mkIDE =
        { isMobile ? false
        , useSecret ? true
        , useIndex ? true
        , useProxy ? false
        , # useMirrorDrive is a boolean to config if copy remote config from google drive by rclone instead of Google drive stream
          useMirrorDrive ? false
        , extraModules ? [ ]
        ,
        }: mkHome {
          modules = [
            ./programs/common
            ./users

            (if useIndex then nix-index-database.hmModules.nix-index else "")
            (if builtins.elem system (builtins.attrNames systemMaps) then ./programs/${systemMaps.${system}} else "")
            (if builtins.pathExists ./programs/${system} then ./programs/${system} else "")
          ] ++ extraModules;

          extraSpecialArgs = {
            inherit isMobile useSecret useProxy useIndex useMirrorDrive;
          };
        };

      mkDarwin =
        { host ? ""
        ,
        }: nix-darwin.lib.darwinSystem {
          inherit system;

          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          modules = log (builtins.filter (el: el != "") [
            (if builtins.elem system (builtins.attrNames systemMaps) then ./hosts/${systemMaps.${system}} else "")

            (if builtins.pathExists ./hosts/${system} then ./hosts/${system} else "")
            (if builtins.pathExists ./hosts/${system}/${host} then ./hosts/${system}/${host} else "")
          ]);

          specialArgs = { inherit inputs; };
        };

      mkAndroid =
        { host ? ""
        ,
        }: nix-on-droid.lib.nixOnDroidConfiguration {
          inherit system;

          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          modules = [
            ./hosts/${system}
            (if builtins.pathExists ./hosts/${system}/${host} then ./hosts/${system}/${host} else "")
          ];
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
              ./users/vpn-server
            ];
          };
          # m3 || wsl || ec2
          ide = mkIDE {
            useSecret = true;
            useIndex = true;
            useProxy = false;
            useMirrorDrive = false;
          };
          # c02fk4mjmd6m
          ide-mirror = mkIDE {
            useSecret = true;
            useIndex = true;
            useProxy = false;
            useMirrorDrive = true;
          };
          # cn ec2
          ide-cn = mkIDE {
            useSecret = true;
            useIndex = true;
            useProxy = true;
            useMirrorDrive = false;
          };
          # mobile
          ide-mobile = mkIDE {
            isMobile = true;
            useSecret = true;
            useIndex = true;
            useProxy = false;
            useMirrorDrive = false;
          };

          # clean all packages & generated files
          clean = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
            };

            modules = [
              ./misc/clean.nix
            ];
          };
        };

        darwinConfigurations = {
          "darwin" = mkDarwin { };
        };

        nixOnDroidConfigurations = {
          "default" = mkAndroid { };
        };
      };
    });
}
