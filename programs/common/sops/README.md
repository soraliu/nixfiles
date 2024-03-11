# Use sops with `age`

## Basic usages of `age`

```sh
# generate keys
age-keygen -o keys.txt
```

## Specify key of age in sops

```sh
export SOPS_AGE_KEY_FILE=/path/to/age/keys.txt
```
