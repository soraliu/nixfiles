#!/usr/bin/env bash

# set default shell to zsh

set -e

path_to_zsh=""
for candidate in \
  "$HOME_PROFILE_DIRECTORY/bin/zsh" \
  "$HOME/.nix-profile/bin/zsh" \
  "/nix/var/nix/profiles/default/bin/zsh" \
  "/run/current-system/sw/bin/zsh" \
  "$(command -v zsh 2>/dev/null)"
do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    path_to_zsh="$(readlink -f "$candidate" 2>/dev/null || printf '%s' "$candidate")"
    break
  fi
done
path_to_config=/etc/shells

if [ -z "$path_to_zsh" ] || [ ! -f "$path_to_zsh" ]; then
  echo "zsh has not been installed. Skip!"
else
  if [ ! -f "$path_to_config" ] || ! grep -q "$path_to_zsh" $path_to_config; then
    mkdir -p $(basename $path_to_config)
    sudo bash -c "echo '$path_to_zsh' >> $path_to_config"
  else
    echo "Info: ${path_to_config} has already configured zsh! Skip."
  fi

  sudo chsh -s "$path_to_zsh"
  echo "Success: ${path_to_zsh} now is the default shell."
fi
