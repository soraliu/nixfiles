# -------------------- pre & post scripts --------------------
pre-init-nix:
	./bin/common/pre-init-nix
pre-init-age:
	./bin/common/pre-init-age
post-init-pm2:
	./bin/common/post-init-pm2
post-init-zsh:
	./bin/common/post-init-zsh
darwin-post-install-pkgs:
	./bin/common-darwin/post-install-pkgs
darwin-post-link-dirs:
	./bin/common-darwin/post-link-dirs
darwin-post-restore-raycast:
	./bin/common-darwin/post-restore-raycast
mobile-pre-init-nix-on-doird:
	./bin/aarch64-linux/pre-init-nix-on-droid



# -------------------- home-manager --------------------
switch-vpn-server:
	nix run .#home-manager -- switch --show-trace --impure --flake .#vpn-server -b backup
switch-ide:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide -b backup
switch-ide-cn:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide-cn -b backup
switch-ide-mobile:
	nix run .#home-manager -- switch --show-trace --impure --flake .#ide-mobile -b backup



# -------------------- nixos --------------------
switch-darwin:
	nix run .#nix-darwin -- switch --show-trace --flake .#darwin
switch-android:
	nix-on-droid switch --show-trace --flake .#default



# -------------------- all-in-one init --------------------
init-vpn-server: pre-init-nix pre-init-age switch-vpn-server post-init-pm2
init-ide: pre-init-nix pre-init-age switch-ide post-init-pm2 post-init-zsh
init-ide-on-darwin: init-ide darwin-post-install-pkgs darwin-post-link-dirs darwin-post-restore-raycast
init-ide-on-mobile: mobile-pre-init-nix-on-doird switch-ide-mobile



# -------------------- utils --------------------
nixd:
	nix eval --json --file .nixd.nix > .nixd.json

# make nix-hash url=https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release/clashpremium-linux-amd64
nix-hash:
	@nix-hash --type sha256 --to-sri $$(nix-prefetch-url "$(url)" 2>/dev/null | tail -n1) 2>/dev/null
