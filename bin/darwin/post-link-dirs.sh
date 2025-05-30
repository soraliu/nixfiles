#!/usr/bin/env bash

set -e

path_to_nix_app="$HOME_PROFILE_DIRECTORY/Applications"
path_to_hm_link="/Applications/Home Manager Apps"
if [ -d "$path_to_nix_app" ] || [ -L "${path_to_nix_app}" ]; then
  [ -L "$path_to_hm_link" ] && unlink "$path_to_hm_link"
  ln -s "$path_to_nix_app" "$path_to_hm_link"

  echo 'Info: Successfully link home-manager apps.'
else
  echo "Error: home-manager app($path_to_nix_app) does not exist."
fi
