# Just: https://github.com/casey/just
#   Set Params: https://just.systems/man/en/recipe-parameters.html
export PATH := `echo "$PATH:$HOME/.nix-profile/bin:/run/current-system/sw/bin"`

[private]
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
# profile: vpn-server, ide, ide-mirror, ide-cn, ide-mobile, eject
switch-home profile="ide":
	nix run .#home-manager -- switch --show-trace --impure --flake .#{{profile}} -b backup



# -------------------- nixos --------------------

[private]
switch-darwin:
	nix run .#nix-darwin -- switch --show-trace --flake .#darwin
[private]
switch-android:
	nix-on-droid switch --show-trace --flake .#default
# os: darwin, android
switch-os os="darwin":
  just switch-{{os}}



# -------------------- all-in-one command --------------------

[private]
init-vpn-server: pre-init-nix pre-init-age (switch-home "vpn-server") post-init-pm2
[private]
init-ide: pre-init-nix pre-init-age (switch-home "ide") post-init-pm2 post-init-zsh
[private]
init-ide-on-darwin-work: init-ide (switch-home "darwin") darwin-post-install-pkgs-work darwin-post-link-dirs darwin-post-restore-raycast
[private]
init-ide-on-darwin-personal: init-ide-on-darwin-work darwin-post-install-pkgs-personal
[private]
init-ide-on-mobile: mobile-pre-init-nix-on-doird (switch-home "ide-mobile")
[private]
eject-darwin: (switch-home "eject") darwin-uninstall-pkgs

# profile: vpn-server, ide, ide-on-darwin-work, ide-on-darwin-personal, ide-on-mobile
init profile="ide":
  just init-{{profile}}

# profile: darwin
eject os="darwin":
  just eject-{{os}}


# -------------------- utils --------------------

[private]
nixd:
	nix eval --json --file .nixd.nix > .nixd.json

# e.g. $ make nix-hash url=https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release/clashpremium-linux-amd64
[private]
nix-hash url:
	@nix-hash --type sha256 --to-sri $(nix-prefetch-url "{{url}}" 2>/dev/null | tail -n1) 2>/dev/null
