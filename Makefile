vpn-server:
	nix run .#homeConfigurations.vpn-server.activationPackage --show-trace --impure

ide:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide-cn

switch-home:
	# `--impure` Allow to use ~/.age directory to decrypt secrets
	nix run .#home-manager -- switch --show-trace --impure --flake .

flake-switch-work-home:
	# `--impure` Allow to use ~/.age directory to decrypt secrets
	nix run .#homeConfigurations.user.activationPackage --show-trace --impure

home-manager-switch-work-with-backup:
	home-manager switch --flake . -b backup

switch-work-host:
	nix run nix-darwin -- switch --flake . --show-trace

nixd:
	nix eval --json --file .nixd.nix > .nixd.json

edit-git-credentials:
	sops ./secrets/.git-credentials.enc

install-nix-darwin:
	nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
	./result/bin/darwin-installer
