#!/usr/bin/env bash

function install_dmg {
  usage() {
    echo "usage:
      [--password|-p]
      [--type|-t] dmg|zip|tar.gz
      [--url|-u]
      [--name|-n]
      [-h]"
  }

  while [ "$1" != "" ]; do
    case $1 in
      -n | --name ) shift
        name=$1
        ;;
      -p | --password ) shift
        password=$1
        ;;
      -u | --uri ) shift
        url=$1
        ;;
      -t | --type ) shift
        type=$1
        ;;
      -h | --help )
        usage
        exit
        ;;
      * )
        usage
        exit 0
    esac
    shift
  done

  if [ "$name" == "" ]; then
    echo "Pls pass --name or -n to the app which is downloaded from: $url"

    exit 1
  fi

  if [ -e "/Applications/${name}" ]; then
    echo "/Applications/${name} has already existed. Skip Installing!"

    return
  fi

  tempd=$(mktemp -d)

  # if url ends with .dmg, download it directly, else if it ends with .zip or .tar.gz, download it and unzip it
  if [[ $url == *.dmg || $type == "dmg" ]]; then
    echo "Downloading $url to $tempd/pkg.dmg..."
    wget -q --show-progress $url -O $tempd/pkg.dmg

    if [[ $password != "" ]]; then
      listing=$(printf $password | hdiutil attach $tempd/pkg.dmg -stdinpass | grep Volumes)
    else
      listing=$(yes | hdiutil attach $tempd/pkg.dmg | grep Volumes)
    fi
    volume=$(echo "$listing" | cut -f 3)
    if [ -e "$volume"/*.app ]; then
      sudo cp -R "$volume"/*.app /Applications
    elif [ -e "$volume"/*.pkg ]; then
      package=$(ls -1 "$volume" | grep .pkg | head -1)
      sudo installer -pkg "$volume"/"$package" -target /Applications
    fi

    hdiutil detach "${volume}"
  elif [[ $url == *.zip || $type == "zip" ]]; then
    echo "Downloading $url to $tempd/pkg.zip..."
    wget -q --show-progress $url -O $tempd/pkg.zip
    unzip $tempd/pkg.zip -d $tempd/apps

    sudo cp -R "$tempd/apps"/*.app /Applications
  elif [[ $url == *.tar.gz || $type == "tar.gz" ]]; then
    echo "Downloading $url to $tempd/pkg.tar.gz..."
    wget -q --show-progress $url -O $tempd/pkg.tar.gz
    tar -xf $tempd/pkg.tar.gz -C $tempd/apps

    sudo cp -R "$tempd/apps"/*.app /Applications
  else
    echo "Unknown file type for $url"
    exit 1
  fi

  rm -rf $tempd
}
