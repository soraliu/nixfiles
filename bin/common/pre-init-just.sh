#!/usr/bin/env bash

set -e

root_dir=$(git rev-parse --show-toplevel)
path_to_just_bin=$root_dir/.local/bin/just

if [ -f "$path_to_just_bin" ]; then
  echo "Info: Just has been installed locally"
else
  echo "Info: Installing just"
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$(dirname $path_to_just_bin)"
fi

path_to_just_link=/usr/local/bin/just

if [ ! -d /usr/local/bin ]; then
  path_to_just_link=/usr/bin/just
fi

if [ -f ${path_to_just_link} ]; then
  echo "Info: just has already linked! Skip."
else
  # Link just to /usr/local/bin
  echo "Info: Link ${path_to_just_bin} -> ${path_to_just_link}"
  sudo ln -sf ${path_to_just_bin} ${path_to_just_link}
fi
