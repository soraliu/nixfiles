#!/usr/bin/env bash

set -e

path_to_database_key=~/.config/raycast_database_key

mkdir -p $(dirname $path_to_database_key)

if [ -f $path_to_database_key ]; then
  security add-generic-password -a database_key -s Raycast -w "$(cat $path_to_database_key)" -T "" -U

  echo "Info: Successfully restore database_key of Raycast in keychain."
else
  echo "Error: Can't find database_key at $path_to_database_key."
fi
