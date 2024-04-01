switch-vpn-server:
	nix run .#home-manager -- switch --show-trace --impure --flake .#vpn-server -b backup

switch-ide:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide -b backup

switch-ide-cn:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide-cn -b backup

switch-darwin:
	nix run nix-darwin -- switch --show-trace --flake .#darwin

nixd:
	nix eval --json --file .nixd.nix > .nixd.json

nix-hash:
	@nix-hash --type sha256 --to-sri $$(nix-prefetch-url "$(url)" 2>/dev/null | tail -n1) 2>/dev/null

install-nix-darwin:
	nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
	./result/bin/darwin-installer

gcmsg-sgpt:
	git commit -m "$$(git diff --cached | sgpt 'Based on the changes, help me generate git commit messages. The first line is the summary in git conventional commit format( \
		The format typically looks like type(scope?): description, where type is a keyword like feat (new feature) or fix (bug fix), scope is an optional identifier for the part of the codebase affected, and description succinctly explains the change. \
	). Then leave an empty line and the rest lines are the details of all changes that will start with -' --no-cache)"
