PATH_TO_DARWIN_NIX=nix

# -------------------- pre & post scripts --------------------
pre-init-nix:
	./bin/common/pre-init-nix
pre-init-age:
	./bin/common/pre-init-age
post-init-pm2:
	./bin/common/post-init-pm2
post-init-zsh:
	./bin/common/post-init-zsh
darwin-post-install-pkgs-work:
	./bin/common-darwin/post-install-pkgs-work
darwin-post-install-pkgs-personal:
	./bin/common-darwin/post-install-pkgs-personal
darwin-post-link-dirs:
	./bin/common-darwin/post-link-dirs
darwin-post-restore-raycast:
	./bin/common-darwin/post-restore-raycast
darwin-uninstall-pkgs:
	sudo ./bin/common-darwin/uninstall-pkgs
mobile-pre-init-nix-on-doird:
	./bin/aarch64-linux/pre-init-nix-on-droid



# -------------------- home-manager --------------------
switch-vpn-server:
	$(PATH_TO_NIX) run .#home-manager -- switch --show-trace --impure --flake .#vpn-server -b backup
switch-ide:
	$(PATH_TO_NIX) run .#home-manager -- switch --show-trace --impure --flake .#ide -b backup
switch-ide-mirror:
	$(PATH_TO_NIX) run .#home-manager -- switch --show-trace --impure --flake .#ide-mirror -b backup
switch-ide-cn:
	$(PATH_TO_NIX) run .#home-manager -- switch --show-trace --impure --flake .#ide-cn -b backup
switch-ide-mobile:
	$(PATH_TO_NIX) run .#home-manager -- switch --show-trace --impure --flake .#ide-mobile -b backup
switch-clean:
	$(PATH_TO_NIX) run .#home-manager -- switch --show-trace --impure --flake .#clean



# -------------------- nixos --------------------
switch-darwin:
	$(PATH_TO_NIX) run .#nix-darwin -- switch --show-trace --flake .#darwin
switch-android:
	nix-on-droid switch --show-trace --flake .#default



# -------------------- all-in-one init --------------------
init-vpn-server: pre-init-nix pre-init-age switch-vpn-server post-init-pm2
init-ide: pre-init-nix pre-init-age switch-ide post-init-pm2 post-init-zsh
init-ide-on-darwin-work: init-ide switch-darwin darwin-post-install-pkgs-work darwin-post-link-dirs darwin-post-restore-raycast
init-ide-on-darwin-personal: init-ide-on-darwin-work darwin-post-install-pkgs-personal
init-ide-on-mobile: mobile-pre-init-nix-on-doird switch-ide-mobile
clean-darwin: switch-clean darwin-uninstall-pkgs



# -------------------- utils --------------------
nixd:
	$(PATH_TO_NIX) eval --json --file .nixd.nix > .nixd.json

# e.g. $ make nix-hash url=https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release/clashpremium-linux-amd64
nix-hash:
	@nix-hash --type sha256 --to-sri $$(nix-prefetch-url "$(url)" 2>/dev/null | tail -n1) 2>/dev/null
