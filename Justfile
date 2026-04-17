# Just: https://github.com/casey/just
#   Set Params: https://just.systems/man/en/recipe-parameters.html
export PATH := `echo "$PATH:${HOME_PROFILE_DIRECTORY:-$HOME/.nix-profile}/bin:/run/current-system/sw/bin"`

[private]
default:
  just --list

# -------------------- pre & post scripts --------------------

[private]
pre-init-nix region="":
	./bin/common/pre-init-nix.sh {{ if region != "" { "-r " + region } else { "" } }}
[private]
pre-init-age:
	./bin/common/pre-init-age.sh
[private]
post-init-zsh:
	./bin/common/post-init-zsh.sh
[private]
post-init-pm2:
	./bin/common/post-init-pm2.sh
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
[private]
record-switch cmd:
	printf '#!/usr/bin/env bash\n%s\n' '{{cmd}}' > .nix-switch
	chmod +x .nix-switch

switch-home profile="ide":
	just record-switch "just switch-home {{profile}}"
	nix run .#home-manager -- switch --show-trace --flake .#{{profile}} -b backup

# 推荐路径: nh home switch (含 diff/build tree/confirm); 需 nh 已装
switch-home-nh profile="ide":
	just record-switch "just switch-home-nh {{profile}}"
	nh home switch . -c {{profile}}

# -------------------- NixOS-WSL --------------------
# profile: ide, wsl-infer
switch-nixos profile="ide":
	just record-switch "just switch-nixos {{profile}}"
	sudo nixos-rebuild switch --show-trace --flake .#{{profile}}

# 推荐路径: nh os switch (含 diff/build tree/confirm); 需 nh 已装
switch-nixos-nh profile="ide":
	just record-switch "just switch-nixos-nh {{profile}}"
	nh os switch . -H {{profile}}

# -------------------- Darwin --------------------
# user: soraliu, soraliu-mirror, clawbot
# 第一次升级到 Determinate Nix 后推荐走 switch-darwin-nh (更好的 diff/UI)
# switch-darwin: 兜底路径, upstream→Determinate 过渡期可用, env PATH preserves nix paths, --extra-experimental-features 解决鸡蛋问题
switch-darwin user="soraliu":
	just record-switch "just switch-darwin {{user}}"
	sudo env PATH="$PATH" nix --extra-experimental-features 'nix-command flakes' run .#nix-darwin -- switch --show-trace --flake .#{{user}}

# 推荐路径: nh darwin switch (含 diff、build tree、confirm); 需 nh 已装 (home-manager 首次 switch 后自然具备)
switch-darwin-nh user="soraliu":
	just record-switch "just switch-darwin-nh {{user}}"
	nh darwin switch . -H {{user}}

# -------------------- Android --------------------
switch-android:
	just record-switch "just switch-android"
	nix-on-droid switch --show-trace --flake .#default

# -------------------- all-in-one command --------------------

[private]
init-vpn-server: pre-init-nix pre-init-age (switch-home "vpn-server") post-init-pm2
[private]
init-vpn-relayer: pre-init-nix pre-init-age (switch-home "vpn-relayer") post-init-pm2
[private]
init-drive-server: (pre-init-nix "cn") pre-init-age (switch-home "drive-server")
[private]
init-ide: pre-init-nix pre-init-age (switch-home "ide") post-init-zsh
[private]
init-ide-cn: (pre-init-nix "cn") pre-init-age (switch-home "ide-cn") post-init-zsh
[private]
init-wsl-nixos: pre-init-nix pre-init-age (switch-nixos "default") post-init-zsh
[private]
init-wsl-nixos-ide: pre-init-nix pre-init-age (switch-nixos "ide") post-init-zsh
[private]
init-wsl-nixos-infer: pre-init-nix pre-init-age (switch-nixos "wsl-infer") post-init-zsh
[private]
init-wsl-ubuntu: pre-init-nix pre-init-age (switch-home "ide") post-init-zsh
[private]
init-wsl-ubuntu-infer: pre-init-nix pre-init-age (switch-home "wsl-infer") post-init-zsh
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

# e.g. $ just nix-hash url=https://github.com/soraliu/clash_singbox-tools/raw/main/ClashPremium-release/clashpremium-linux-amd64
[private]
nix-hash url:
	@nix-hash --type sha256 --to-sri $(nix-prefetch-url "{{url}}" 2>/dev/null | tail -n1) 2>/dev/null

# -------------------- bin --------------------
# init linux bbr/bbrplus + fq/cake
bin-bbr:
	./bin/vpn-server/bbr.sh

[private]
sops file args:
  sops -d {{file}} | bash -s -- {{args}}

# @params: ["frpc", "frpc-drive"], rebuild frpc docker image & restart frpc on remote server
# @deprecated: use vpn mesh instead
bin-restart-frpc frpc="frpc":
  @just sops ./secrets/bin/x86_64-linux/frp/restart-frpc.enc.sh "{{frpc}}"

# -------------------- flake --------------------
update-unstable-pkg:
  nix flake update nixpkgs-unstable
