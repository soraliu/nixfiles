#!/usr/bin/env bash

# set default shell to zsh

set -e

path_to_zsh="$(readlink -f ~/.nix-profile/bin/zsh 2>/dev/null)"
path_to_config=/etc/shells

if [ ! -f "$path_to_zsh" ]; then
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
