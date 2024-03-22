## Run a nix expression in repl

```sh
nix repl -f /path/to/exp.nix
```

## Build a derivation

```sh
nix-build /path/to/drv.nix
```

## Show logs of a nix pacakge

```sh
nix log /nix/store/h7cmjv5j4paa9wr14bxrwknm9kjwh7rr-demo
```


## Use `nix-store` to Analyze Dependencies

```sh
# show who depends on specific dir
nix-store --query --referrers /nix/store/xxx-package-name-version
# show direct dependants
nix-store -q --requisites /nix/store/...-package-name-version
# show deps tree
nix-store -q --tree /nix/store/...-package-name-version
```
