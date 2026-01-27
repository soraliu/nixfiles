#!/usr/bin/env bash

set -e

# global, cn
region=global
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--region)
            region="$2"
            shift 2
            ;;
        *)
            echo "unknown arg: $0 $1"
            usage
            ;;
    esac
done

# Install nix

case $region in
  global)
    # global
    download_url="https://releases.nixos.org/nix/nix-2.28.2/install"
    nix_version_25=https://nixos.org/channels/nixos-25.11
    nix_version_unstable=https://nixos.org/channels/nixos-unstable
    substituters="https://cache.nixos.org https://nix-community.cachix.org"
    ;;
  cn)
    # cn
    download_url="https://mirrors.tuna.tsinghua.edu.cn/nix/latest/install"
    nix_version_25=https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-25.11
    nix_version_unstable=https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-unstable
    substituters="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org https://nix-community.cachix.org"
    ;;
  *)
    echo "unknown region: $region"
    exit 1
esac

if [ ! -d /nix ]; then
  os_type=$(uname)

  if [ $os_type == "Darwin" ]; then
    curl -L "$download_url" | sh -s -- --no-channel-add --yes
  elif [ $os_type == "Linux" ]; then
    curl -L "$download_url" | sh -s -- --no-channel-add --yes --daemon
  else
      echo "Unsupported OS"
      exit 1
  fi
else
  echo "Info: nix has already installed! Skip."
fi

# Enable nix-command and flakes
path_to_nix_config=$HOME/.config/nix/nix.conf
mkdir -p $(dirname $path_to_nix_config)

# experimental-features
config_experimental="experimental-features = nix-command flakes"
if [ ! -f "$path_to_nix_config" ] || ! grep -q "experimental-features" $path_to_nix_config; then
  echo "$config_experimental" >> $path_to_nix_config
else
  echo "Info: experimental-features already configured! Skip."
fi

# substituters
config_substituters="substituters = $substituters"
if ! grep -q "^substituters" $path_to_nix_config; then
  echo "$config_substituters" >> $path_to_nix_config
  echo "Info: substituters configured: $substituters"
else
  echo "Info: substituters already configured! Skip."
fi

# trusted-public-keys
config_trusted_keys="trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
if ! grep -q "^trusted-public-keys" $path_to_nix_config; then
  echo "$config_trusted_keys" >> $path_to_nix_config
  echo "Info: trusted-public-keys configured"
else
  echo "Info: trusted-public-keys already configured! Skip."
fi

# trusted substituters
trusted_settings="{\"extra-trusted-public-keys\":{\"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=\":true},\"substituters\":{\"${substituters}\":true}}"
path_to_trusted_settings=$HOME/.local/share/nix/trusted-settings.json
if [ ! -f "$path_to_trusted_settings" ]; then
  mkdir -p $(dirname $path_to_trusted_settings)
  echo "$trusted_settings" >> $path_to_trusted_settings
else
  echo "Info: ${path_to_trusted_settings} has already existed! Skip."
fi

# Specify the version of nixpkgs
nix_bin=$([ -z "$(command -v nix-channel)" ] && echo "/nix/var/nix/profiles/default/bin/nix-channel" || echo "nix-channel")
function set_nix_channel() {
  local channel_name=$1
  local channel_url=$2

  if [[ "$(${nix_bin} --list | grep "$channel_name" | cut -d ' ' -f 2)" == "$channel_url" ]]; then
    echo "Info: ${channel_name} ${channel_url} already exists! Skip."
  else
    echo "Info: ${channel_name} ${channel_url} does not exist! Updating..."
    ${nix_bin} --remove "$channel_name"
    ${nix_bin} --add "$channel_url" "$channel_name"
    ${nix_bin} --update
  fi
}
set_nix_channel "nixos-25.11" $nix_version_25
set_nix_channel nixpkgs $nix_version_unstable

path_to_nix_link=/usr/local/bin
if [ ! -d /usr/local/bin ]; then
  path_to_nix_link=/usr/bin
fi

if [ -f ${path_to_nix_link}/nix ]; then
  echo "Info: nix && nix-build have already linked! Skip."
else
  # Link nix to /usr/local/bin
  if [ -e $HOME/.nix-profile/bin ]; then
    # linux
    path_to_nix_bin=$HOME/.nix-profile/bin
  elif [ -e /run/current-system/sw/bin ]; then
    # macos
    path_to_nix_bin=/run/current-system/sw/bin
  elif [ -e /nix/var/nix/profiles/default/bin ]; then
    # wsl
    path_to_nix_bin=/nix/var/nix/profiles/default/bin
  else
    echo "Error: nix binary not found!"
    exit 1
  fi

  sudo ln -sf ${path_to_nix_bin}/nix ${path_to_nix_link}/nix
fi
