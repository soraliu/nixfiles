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
    download_url="https://releases.nixos.org/nix/nix-2.28.2/install"
    substituters="https://cache.nixos.org https://nix-community.cachix.org"
    ;;
  cn)
    download_url="https://mirrors.tuna.tsinghua.edu.cn/nix/latest/install"
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

# extra-sandbox-paths: 允许 Nix 沙箱访问 age 密钥目录，用于 sops 解密
age_path="/tmp/.age"
config_sandbox_paths="extra-sandbox-paths = $age_path"
if ! grep -q "^extra-sandbox-paths" $path_to_nix_config; then
  mkdir -p $age_path
  echo "$config_sandbox_paths" >> $path_to_nix_config
  echo "Info: extra-sandbox-paths configured: $age_path"
else
  echo "Info: extra-sandbox-paths already configured! Skip."
fi

# Link nix to /usr/local/bin for scripts that depend on this path
path_to_nix_link=/usr/local/bin
if [ ! -d "$path_to_nix_link" ]; then
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
