s:
	nix run .#homeConfigurations.root.activationPackage --show-trace

switch-work-home:
	nix run .#homeConfigurations.user.activationPackage --show-trace

home-manager-switch-work-with-backup:
	home-manager switch --flake . -b backup

switch-work-host:
	nix run nix-darwin -- switch --flake .

nixd:
	nix eval --json --file .nixd.nix > .nixd.json

edit-git-credentials:
	sops ./secrets/.git-credentials.enc

install-nix-darwin:
	nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
	./result/bin/darwin-installer


