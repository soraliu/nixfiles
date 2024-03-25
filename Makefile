switch-vpn-server:
	nix run .#home-manager -- switch --show-trace --impure --flake .#vpn-server

switch-ide:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide -b backup

switch-ide-cn:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide-cn

switch-work-host:
	nix run nix-darwin -- switch --flake . --show-trace

nixd:
	nix eval --json --file .nixd.nix > .nixd.json

edit-git-credentials:
	sops ./secrets/.git-credentials.enc

install-nix-darwin:
	nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
	./result/bin/darwin-installer
