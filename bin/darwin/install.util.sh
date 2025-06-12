#!/usr/bin/env bash
set -e

install() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --url|-u) url="$2"; shift ;;
      --name|-n) name="$2"; shift ;;
      --type|-t) type="$2"; shift ;;  # optional override
      --password|-p) password="$2"; shift ;;  # for encrypted dmg
      *) echo "Unknown option $1"; exit 1 ;;
    esac
    shift
  done

  if [[ -z "$url" || -z "$name" ]]; then
    echo "Usage: $0 --url <url> --name <AppName> [--type dmg|zip|pkg|tar.gz] [--password <password>]"
    exit 1
  fi

  if [ -e "/Applications/${name}" ]; then
    echo "/Applications/${name} has already existed. Skip Installing!"
    return
  fi

  tempd=$(mktemp -d)
  mkdir -p "$tempd/apps"

  if [[ $url == *.dmg || $type == "dmg" ]]; then
    echo "Downloading $url to $tempd/pkg.dmg..."
    wget -q --show-progress "$url" -O "$tempd/pkg.dmg"

    mountpoint="$tempd/mount"
    mkdir -p "$mountpoint"

    if [[ -n "$password" ]]; then
      echo "$password" | hdiutil attach "$tempd/pkg.dmg" -mountpoint "$mountpoint" -quiet -stdinpass
    else
      hdiutil attach "$tempd/pkg.dmg" -mountpoint "$mountpoint" -quiet
    fi

    if compgen -G "$mountpoint"/*.app > /dev/null; then
      sudo cp -R "$mountpoint"/*.app /Applications
    elif compgen -G "$mountpoint"/*.pkg > /dev/null; then
      pkgfile=$(ls "$mountpoint"/*.pkg | head -1)
      sudo installer -pkg "$pkgfile" -target /
    else
      echo "❌ No .app or .pkg found in dmg"
    fi

    hdiutil detach "$mountpoint" -quiet || true

  elif [[ $url == *.zip || $type == "zip" ]]; then
    echo "Downloading $url to $tempd/pkg.zip..."
    wget -q --show-progress "$url" -O "$tempd/pkg.zip"
    unzip -q "$tempd/pkg.zip" -d "$tempd/apps"
    sudo cp -R "$tempd/apps"/*.app /Applications

  elif [[ $url == *.tar.gz || $type == "tar.gz" ]]; then
    echo "Downloading $url to $tempd/pkg.tar.gz..."
    wget -q --show-progress "$url" -O "$tempd/pkg.tar.gz"
    tar -xf "$tempd/pkg.tar.gz" -C "$tempd/apps"
    sudo cp -R "$tempd/apps"/*.app /Applications

  elif [[ $url == *.pkg || $type == "pkg" ]]; then
    echo "Downloading $url to $tempd/pkg.pkg..."
    wget -q --show-progress "$url" -O "$tempd/pkg.pkg"
    sudo installer -pkg "$tempd/pkg.pkg" -target /

  else
    echo "Unknown or unsupported file type for $url"
    exit 1
  fi

  rm -rf "$tempd"
  echo "✅ Installation of $name completed."
}
