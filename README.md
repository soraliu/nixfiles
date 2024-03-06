# nixfiles

Nix Configurations

## Installation

- https://nixos.org/download
- https://nix.dev/install-nix

# Architecture

```
├── bin             # reusable scripts
├── hosts           # configure host
├── pkgs            # users packages deps
├── programs        # same as pkgs but those packages are configurable
├── secrets         # encrypted secrets
├── users           # configure user's home
├── flake.lock      # flake lock file
└── flake.nix       # flake configurations
```

## The Way to Declare a Package That needs to be depended on

Just declare it in `./programs/common/default.nix` or `./programs/${os}/default.nix`.

```
programs
├── common
│   ├── default.nix
│   └── ...
├── x86_64-darwin
│   ├── default.nix
│   └── ...
└── x86_64-linux
    ├── default.nix
    └── ...
```

If `home-manager` supports to configure them those packages, you have to create your own pkg and import them. E.g.: `./programs/common/sops.nix`.

## The Way to Declare Configurations That to Be Used by OS and Users

Put those configurations in `./hosts/${os}/${hostName}/default.nix` or `./hosts/${os}/${user}.nix`

```
hosts
└── x86_64-darwin
    └── c02fk4mjmd6m
        ├── default.nix
        └── ...
users
└── x86_64-darwin
    ├── user.nix
    └── ...
```

