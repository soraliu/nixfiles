default:
  just --list

# -------------------- pre & post scripts --------------------

[private]
pre-init-nix:
	./bin/common/pre-init-nix.sh
[private]
pre-init-age:
	./bin/common/pre-init-age.sh
[private]
post-init-pm2:
	./bin/common/post-init-pm2.sh
[private]
post-init-zsh:
	./bin/common/post-init-zsh.sh
[private]
darwin-post-install-pkgs-work:
	./bin/darwin/post-install-pkgs-work.sh
[private]
darwin-post-install-pkgs-personal:
	./bin/darwin/post-install-pkgs-personal.sh
[private]
darwin-post-link-dirs:
	./bin/darwin/post-link-dirs.sh
[private]
darwin-post-restore-raycast:
	./bin/darwin/post-restore-raycast.sh
[private]
darwin-uninstall-pkgs:
	sudo ./bin/darwin/uninstall-pkgs.sh
[private]
mobile-pre-init-nix-on-doird:
	./bin/android/pre-init-nix-on-droid.sh



# -------------------- home-manager --------------------
# profile: ide, ide-mirror, ide-cn, ide-mobile, vpn-server, clean
switch-home profile="ide":
	nix run .#home-manager -- switch --show-trace --impure --flake .#{{profile}} -b backup



# -------------------- nixos --------------------

switch-darwin:
	nix run .#nix-darwin -- switch --show-trace --flake .#darwin
switch-android:
	nix-on-droid switch --show-trace --flake .#default



# -------------------- all-in-one command --------------------

init-vpn-server: pre-init-nix pre-init-age (switch-home "vpn-server") post-init-pm2
init-ide: pre-init-nix pre-init-age (switch-home "ide") post-init-pm2 post-init-zsh
init-ide-on-darwin-work: init-ide (switch-home "darwin") darwin-post-install-pkgs-work darwin-post-link-dirs darwin-post-restore-raycast
init-ide-on-darwin-personal: init-ide-on-darwin-work darwin-post-install-pkgs-personal
init-ide-on-mobile: mobile-pre-init-nix-on-doird (switch-home "ide-mobile")
clean-darwin: (switch-home "clean") darwin-uninstall-pkgs



# -------------------- utils --------------------

nixd:
	nix eval --json --file .nixd.nix > .nixd.json

# e.g. $ make nix-hash url=https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release/clashpremium-linux-amd64

nix-hash url:
	@nix-hash --type sha256 --to-sri $(nix-prefetch-url "{{url}}" 2>/dev/null | tail -n1) 2>/dev/null
