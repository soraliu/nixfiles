# nixfiles

Nix Configurations

## Installation

- https://nixos.org/download
- https://nix.dev/install-nix

```sh
./bin/common/init-nix
```

# Architecture

```
├── bin             # reusable scripts
├── hosts           # configure host
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

If `home-manager` does not support to configure those packages, you have to create your own pkg and import them. E.g.: `./programs/common/sops`.

## The Way to Declare Configurations That to Be Used by OS and Users

Put those configurations in `./hosts/${os}/${hostName}/default.nix` or `./hosts/${os}/${user}/default.nix`

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

## Run `home-manager` or `nix-darwin` without install them.

```sh
nix run .#home-manager -- switch --impure --show-trace --flake .
nix run .#nix-darwin -- switch --flake .
