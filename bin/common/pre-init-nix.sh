#!/usr/bin/env bash

set -e

# Install nix
if [ ! -d /nix ]; then
  os_type=$(uname)

  if [ $os_type == "Darwin" ]; then
    curl -L https://releases.nixos.org/nix/nix-2.19.3/install | sh -s
  elif [ $os_type == "Linux" ]; then
    curl -L https://releases.nixos.org/nix/nix-2.19.3/install | sh -s -- --daemon
  else
      echo "Unsupported OS"
      exit 1
  fi
else
  echo "Info: nix has already installed! Skip."
fi

# Enable nix-command and flakes
# TODO: add trusted users and substituters
config="experimental-features = nix-command flakes"
path_to_nix_config=$HOME/.config/nix/nix.conf
if [ ! -f "$path_to_nix_config" ] || ! grep -q "$config" $path_to_nix_config; then
  mkdir -p $(dirname $path_to_nix_config)
  echo "$config" >> $path_to_nix_config
else
  echo "Info: ${path_to_nix_config} has already support nix flake! Skip."
fi

# Specify the version of nixpkgs
nix_version_name=nixos-23.11
nix_version=https://nixos.org/channels/nixos-23.11
nix_bin=$([ -z "$(command -v nix-channel)" ] && echo "/nix/var/nix/profiles/default/bin/nix-channel" || echo "nix-channel")
if [[ "$(${nix_bin} --list | grep "$nix_version_name" | cut -d ' ' -f 2)" == "${nix_version}" ]]; then
  echo "Info: ${nix_version_name} ${nix_version} already exists! Skip."
else
  echo "Info: ${nix_version_name} ${nix_version} does not exist! Updating..."
  ${nix_bin} --remove "$nix_version_name"
  ${nix_bin} --add "$nix_version"
  ${nix_bin} --update
fi

path_to_nix_link=/usr/local/bin/nix
if [ -f ${path_to_nix_link} ]; then
  echo "Info: nix has already linked! Skip."
else
  # Link nix to /usr/local/bin
  if [ -f $HOME/.nix-profile/bin/nix ]; then
    # linux
    path_to_nix_bin=$HOME/.nix-profile/bin/nix
  elif [ -f /run/current-system/sw/bin/nix ]; then
    # macos
    path_to_nix_bin=/run/current-system/sw/bin/nix
  else
    echo "Error: nix binary not found!"
    exit 1
  fi

  sudo ln -sf ${path_to_nix_bin} ${path_to_nix_link}
fi
