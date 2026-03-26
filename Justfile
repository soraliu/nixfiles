# Just: https://github.com/casey/just
#   Set Params: https://just.systems/man/en/recipe-parameters.html
export PATH := `echo "$PATH:${HOME_PROFILE_DIRECTORY:-$HOME/.nix-profile}/bin:/run/current-system/sw/bin"`

[private]
default:
  just --list

# -------------------- pre & post scripts --------------------

[private]
pre-init-nix:
	./bin/common/pre-init-nix.sh
[private]
pre-init-nix-cn:
	./bin/common/pre-init-nix.sh -r cn
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
darwin-post-install-pkgs-dev:
	./bin/darwin/post-install-pkgs-dev.sh
[private]
darwin-post-install-pkgs-work:
	./bin/darwin/post-install-pkgs-work.sh
[private]
darwin-post-install-pkgs-personal:
	./bin/darwin/post-install-pkgs-personal.sh
[private]
darwin-post-restore-raycast:
	./bin/darwin/post-restore-raycast.sh
[private]
darwin-uninstall-pkgs:
	sudo ./bin/darwin/uninstall-pkgs.sh
[private]
mobile-pre-init-nix-on-doird:
	./bin/android/pre-init-nix-on-droid.sh



# -------------------- home-manager - standalone --------------------
# profile: ide, ide-mirror, ide-cn, ide-mobile, wsl-infer, clawbot, vpn-server, drive-server, eject
switch-home profile="ide":
	nix run .#home-manager -- switch --show-trace --flake .#{{profile}} -b backup

# -------------------- NixOS-WSL --------------------
# profile: ide, wsl-infer
switch-nixos profile="ide":
  nixos-rebuild switch --show-trace --flake .#{{profile}}

# -------------------- Ubuntu WSL2 --------------------
# profile: ide, wsl-infer  (alias for switch-home)
switch-ubuntu profile="ide":
	nix run .#home-manager -- switch --show-trace --flake .#{{profile}} -b backup

# -------------------- Darwin --------------------
# user: soraliu, soraliu-mirror, clawbot
# New nix-darwin requires root activation; env PATH preserves nix paths; --extra-experimental-features solves first-time activation chicken-egg issue
switch-darwin user="soraliu":
	sudo env PATH="$PATH" nix --extra-experimental-features 'nix-command flakes' run .#nix-darwin -- switch --show-trace --flake .#{{user}}

# -------------------- Android --------------------
switch-android:
	nix-on-droid switch --show-trace --flake .#default

# -------------------- all-in-one command --------------------

[private]
init-vpn-server: pre-init-nix pre-init-age (switch-home "vpn-server") post-init-pm2
[private]
init-drive-server: pre-init-nix-cn pre-init-age (switch-home "drive-server") post-init-pm2
[private]
init-ide: pre-init-nix pre-init-age (switch-home "ide") post-init-pm2 post-init-zsh
[private]
init-ide-cn: pre-init-nix-cn pre-init-age (switch-home "ide-cn") post-init-pm2 post-init-zsh
[private]
init-wsl-nixos: pre-init-nix pre-init-age (switch-ubuntu "ide") post-init-zsh
[private]
init-wsl-nixos-infer: pre-init-nix pre-init-age (switch-ubuntu "wsl-infer") post-init-zsh
[private]
init-wsl-ubuntu: pre-init-nix pre-init-age (switch-ubuntu "ide") post-init-pm2 post-init-zsh
[private]
init-wsl-ubuntu-infer: pre-init-nix pre-init-age (switch-ubuntu "wsl-infer") post-init-pm2 post-init-zsh
[private]
init-ide-on-darwin-dev: pre-init-nix pre-init-age (switch-darwin "soraliu") darwin-post-install-pkgs-dev
[private]
init-ide-on-darwin-work: init-ide-on-darwin-dev darwin-post-install-pkgs-work darwin-post-restore-raycast
[private]
init-ide-on-darwin-personal: init-ide-on-darwin-work darwin-post-install-pkgs-personal
[private]
init-clawbot-on-darwin: pre-init-nix pre-init-age (switch-darwin "clawbot")
[private]
init-ide-on-mobile: mobile-pre-init-nix-on-doird (switch-home "ide-mobile")
[private]
eject-darwin: (switch-home "eject") darwin-uninstall-pkgs

# profile: vpn-server, drive-server, ide, ide-on-darwin-dev, ide-on-darwin-work, ide-on-darwin-personal, wsl-ubuntu, wsl-ubuntu-infer, clawbot-on-darwin, ide-on-mobile
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

# -------------------- bin --------------------
[private]
sops file args:
  sops -d {{file}} | bash -s -- {{args}}

# init linux bbr/bbrplus + fq/cake
bin-bbr:
	./bin/vpn-server/bbr.sh

# @params: ["frpc", "frpc-drive"], rebuild frpc docker image & restart frpc on remote server
bin-restart-frpc frpc="frpc":
  @just sops ./secrets/bin/x86_64-linux/frp/restart-frpc.enc.sh "{{frpc}}"

# -------------------- flake --------------------
update-unstable-pkg:
  nix flake update nixpkgs-unstable


# -------------------- ai --------------------
vllm-serve:
    cd home/modules/ai/vllm && nix run .#vllm-serve
