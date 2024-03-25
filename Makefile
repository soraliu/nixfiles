switch-vpn-server:
	nix run .#home-manager -- switch --show-trace --impure --flake .#vpn-server -b backup

switch-ide:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide -b backup

switch-ide-cn:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide-cn -b backup

switch-work-host:
	nix run nix-darwin -- switch --flake . --show-trace

nixd:
	nix eval --json --file .nixd.nix > .nixd.json

nix-hash:
	@nix-hash --type sha256 --to-sri $$(nix-prefetch-url "$(url)" 2>/dev/null | tail -n1) 2>/dev/null

install-nix-darwin:
	nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
	./result/bin/darwin-installer
