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
    nix_version=https://nixos.org/channels/nixos-24.11
    ;;
  cn)
    # cn
    download_url="https://mirrors.tuna.tsinghua.edu.cn/nix/latest/install"
    nix_version=https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-24.11
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
config="experimental-features = nix-command flakes"
path_to_nix_config=$HOME/.config/nix/nix.conf
if [ ! -f "$path_to_nix_config" ] || ! grep -q "$config" $path_to_nix_config; then
  mkdir -p $(dirname $path_to_nix_config)
  echo "$config" >> $path_to_nix_config
else
  echo "Info: ${path_to_nix_config} has already support nix flake! Skip."
fi

# trusted substituters
trusted_settings='{"extra-trusted-public-keys":{"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=":true},"substituters":{"https://cache.nixos.org https://nix-community.cachix.org":true}}'
path_to_trusted_settings=$HOME/.local/share/nix/trusted-settings.json
if [ ! -f "$path_to_trusted_settings" ]; then
  mkdir -p $(dirname $path_to_trusted_settings)
  echo "$trusted_settings" >> $path_to_trusted_settings
else
  echo "Info: ${path_to_trusted_settings} has already existed! Skip."
fi

# Specify the version of nixpkgs
nix_version_name=nixos-24.11
nix_bin=$([ -z "$(command -v nix-channel)" ] && echo "/nix/var/nix/profiles/default/bin/nix-channel" || echo "nix-channel")
if [[ "$(${nix_bin} --list | grep "$nix_version_name" | cut -d ' ' -f 2)" == "${nix_version}" ]]; then
  echo "Info: ${nix_version_name} ${nix_version} already exists! Skip."
else
  echo "Info: ${nix_version_name} ${nix_version} does not exist! Updating..."
  ${nix_bin} --remove "$nix_version_name"
  ${nix_bin} --add "$nix_version"
  ${nix_bin} --update
fi

path_to_nix_link=/usr/local/bin
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
