s:
	nix run .#homeConfigurations.root.activationPackage --show-trace

nixd:
	nix eval --json --file .nixd.nix > .nixd.json
