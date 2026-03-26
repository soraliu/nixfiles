{
  description = "Home Manager configuration";

  nixConfig = {
    # Allow sandbox to access age key for sops decryption
    extra-sandbox-paths = [ "/tmp/.age" ];

    # override the default substituters
    # uncomment to use specific mirrors
    # substituters = [
    #   # cache mirror located in China
    #   # status: https://mirror.sjtu.edu.cn/
    #   "https://mirror.sjtu.edu.cn/nix-channels/store"
    #   # status: https://mirrors.ustc.edu.cn/status/
    #   "https://mirrors.ustc.edu.cn/nix-channels/store"

    #   "https://cache.nixos.org"

    #   # nix community's cache server
    #   "https://nix-community.cachix.org"
    # ];
    extra-trusted-public-keys = [
      # nix community's cache server public key
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    # Version controlled by ./versions.nix - keep in sync!
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database = {
      url = "github:nix-community/nix-index-database/e76ff2df6bfd2abe06abd8e7b9f217df941c1b07";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      # Version controlled by ./versions.nix - keep in sync!
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      # Version controlled by ./versions.nix - keep in sync!
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
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

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };

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
    , claude-code
    , ...
    }: with flake-utils.lib; eachDefaultSystem (system:
    let
      log = v: builtins.trace v v;
      pkgs = builtins.trace system (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
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
        frpc-drive = import ./docker/frpc.nix {
          inherit system;
          inherit pkgs;
          variant = "frpc-drive";
        };
        immortalwrt = import ./docker/immortalwrt/default.nix {
          inherit system;
          inherit pkgs;
        };
      };

      # User identity info — same profile different users via secretsUser
      userProfiles = {
        soraliu = {
          gitName = "Sora Liu";
          gitEmail = "soraliu.dev@gmail.com";
        };
        clawbot = {
          gitName = "Tiger Wang";
          gitEmail = "tigerwang.pro@gmail.com";
        };
      };

      mkHomeExtraSpecialArgs =
        { useSecret ? true
        , useProxy ? false
        , useMirrorDrive ? false # useMirrorDrive is a boolean to config if copy remote config from google drive by rclone instead of Google drive stream
        , isMobile ? false
        , secretsUser ? "soraliu"
        }: {
          inherit useSecret useProxy useMirrorDrive isMobile secretsUser;
          userProfile = userProfiles.${secretsUser} or userProfiles.soraliu;
        };

      # homeModules — Single Source of Truth for home profile imports
      homeModules = {
        ide = [ ./home/profiles/ide.nix nix-index-database.hmModules.nix-index ];
        clawbot = [ ./home/profiles/clawbot.nix nix-index-database.hmModules.nix-index ];
        wsl-infer = [ ./home/profiles/wsl-infer.nix nix-index-database.hmModules.nix-index ];
        vpn-server = [ ./home/profiles/vpn-server.nix ];
        drive-server = [ ./home/profiles/drive-server.nix ];
        eject = [ ./home/profiles/eject.nix ];
      };

      mkHome =
        { modules ? [ ]
        , homeUser ? "soraliu"
        , extraSpecialArgs ? (mkHomeExtraSpecialArgs { })
        }: home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = log (builtins.filter (el: el != "") modules);

          # Nix has dynamic scope, extraSpecialArgs will be passed to evalModules as the scope of funcitons,
          #   which means those functions can access `useSecret` directly instead of `specialArgs.useSecret`
          #   TL;DR: https://github.com/nix-community/home-manager/blob/36f873dfc8e2b6b89936ff3e2b74803d50447e0a/modules/default.nix#L26
          extraSpecialArgs = {
            inherit system unstablePkgs homeUser claude-code;
          } // extraSpecialArgs;
        };

      mkNixOS = {
        modules ? [],
        homeImports ? [],
        homeUser ? "soraliu",
        extraSpecialArgs ? (mkHomeExtraSpecialArgs { })
      }: nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {
          inherit unstablePkgs homeUser claude-code;
        } // extraSpecialArgs;

        modules = log (builtins.filter (el: el != "") (modules ++ [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit system unstablePkgs homeUser claude-code;
            } // extraSpecialArgs;

            home-manager.users.${homeUser} = {
              imports = homeImports;
              home.username = nixpkgs.lib.mkForce homeUser;
              home.homeDirectory = nixpkgs.lib.mkForce (
                if homeUser == "root" then "/root" else "/home/${homeUser}"
              );
            };
          }
        ]));
      };

      mkDarwin = {
        modules ? [],
        homeImports ? [],
        homeUser ? "soraliu",
        extraSpecialArgs ? (mkHomeExtraSpecialArgs { })
      }: nix-darwin.lib.darwinSystem {
        inherit system pkgs;
        specialArgs = { inherit unstablePkgs homeUser claude-code; };

        modules = log (modules ++ [
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.extraSpecialArgs = {
              inherit system unstablePkgs homeUser claude-code;
            } // extraSpecialArgs;

            # useUserPackages = false 时 home-manager 的 common.nix 会读取 config.users.users.${name}
            users.users.${homeUser}.home = "/Users/${homeUser}";

            home-manager.users.${homeUser} = {
              imports = homeImports;
              home.username = nixpkgs.lib.mkForce homeUser;
              home.homeDirectory = nixpkgs.lib.mkForce "/Users/${homeUser}";
            };
          }
        ]);
      };
    in
    {
      packages = {
        home-manager = home-manager.packages.${system}.default;
        nix-darwin = nix-darwin.packages.${system}.default;
        nix-on-droid = nix-on-droid.packages.${system};

        homeConfigurations = {
          # soraliu — default user
          ide          = mkHome { modules = homeModules.ide; };
          ide-mirror   = mkHome { modules = homeModules.ide; extraSpecialArgs = mkHomeExtraSpecialArgs { useMirrorDrive = true; }; };
          ide-cn       = mkHome { modules = homeModules.ide; extraSpecialArgs = mkHomeExtraSpecialArgs { useProxy = true; }; };
          ide-mobile   = mkHome { modules = homeModules.ide; extraSpecialArgs = mkHomeExtraSpecialArgs { isMobile = true; useMirrorDrive = true; }; };
          wsl-infer    = mkHome { modules = homeModules.wsl-infer; };

          # clawbot — ide + openclaw, independent profile
          clawbot      = mkHome { modules = homeModules.clawbot; homeUser = "clawbot"; extraSpecialArgs = mkHomeExtraSpecialArgs { secretsUser = "clawbot"; }; };

          # servers
          vpn-server   = mkHome { modules = homeModules.vpn-server; homeUser = "root"; };
          drive-server = mkHome { modules = homeModules.drive-server; };

          # utility
          eject        = mkHome { modules = homeModules.eject; };
        };

        darwinConfigurations = {
          # soraliu dev environment: just switch-darwin
          "soraliu" = mkDarwin {
            modules = [ ./systems/darwin.nix ];
            homeImports = homeModules.ide;
          };
          # soraliu mirror drive: just switch-darwin soraliu-mirror
          "soraliu-mirror" = mkDarwin {
            modules = [ ./systems/darwin.nix ];
            homeImports = homeModules.ide;
            extraSpecialArgs = mkHomeExtraSpecialArgs { useMirrorDrive = true; };
          };
          # clawbot environment: just switch-darwin clawbot
          "clawbot" = mkDarwin {
            modules = [ ./systems/darwin.nix { ids.gids.nixbld = 350; } ];
            homeImports = homeModules.clawbot;
            homeUser = "clawbot";
            extraSpecialArgs = mkHomeExtraSpecialArgs { secretsUser = "clawbot"; };
          };
        };

        nixosConfigurations = {
          # NixOS-WSL: just switch-nixos ide
          ide = mkNixOS {
            modules = [ nixos-wsl.nixosModules.default ./systems/nixos-wsl.nix ];
            homeImports = homeModules.ide;
            homeUser = "soraliu";
          };
          # NixOS-WSL: just switch-nixos wsl-infer
          wsl-infer = mkNixOS {
            modules = [ nixos-wsl.nixosModules.default ./systems/nixos-wsl.nix ];
            homeImports = homeModules.wsl-infer;
            homeUser = "soraliu";
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
