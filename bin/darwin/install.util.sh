#!/usr/bin/env bash
set -e

# Copy .app file(s) to target path
copy_app() {
  local source_dir="$1"
  local target_path="$2"
  
  target_dir=$(dirname "$target_path")
  sudo mkdir -p "$target_dir"
  app_file=$(ls -d "$source_dir"/*.app | head -1)
  sudo cp -R "$app_file" "$target_path"
}

install() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --url|-u) url="$2"; shift ;;
      --name|-n) name="$2"; shift ;;
      --type|-t) type="$2"; shift ;;  # optional override
      --password|-p) password="$2"; shift ;;  # for encrypted dmg
      --archived|-a) archived=true; ;;
      *) echo "Unknown option $1"; exit 1 ;;
    esac
    shift
  done

  if [[ -z "$url" || -z "$name" ]]; then
    echo "Usage: $0 --url <url> --name <AppName> [--type dmg|zip|pkg|tar.gz] [--password <password>] [--archived]"
    exit 1
  fi

  # Support absolute path for -n parameter
  if [[ "$name" == /* ]]; then
    target_path="$name"
  else
    target_path="/Applications/${name}"
  fi

  if [ -e "$target_path" ]; then
    echo "$target_path has already existed. Skip Installing!"
    return
  fi

  tempd=$(mktemp -d)
  mkdir -p "$tempd/apps"

  if [[ -n "$archived" ]]; then
    # Handle archived files (zip or tar.gz containing dmg or pkg)
    if [[ $url == *.zip || $type == "zip" ]]; then
      echo "Downloading archived file $url to $tempd/pkg.zip..."
      wget -q --show-progress "$url" -O "$tempd/pkg.zip"
      
      extracted_dir="$tempd/extracted"
      mkdir -p "$extracted_dir"
      unzip -q "$tempd/pkg.zip" -d "$extracted_dir"
      
    elif [[ $url == *.tar.gz || $type == "tar.gz" ]]; then
      echo "Downloading archived file $url to $tempd/pkg.tar.gz..."
      wget -q --show-progress "$url" -O "$tempd/pkg.tar.gz"
      
      extracted_dir="$tempd/extracted"
      mkdir -p "$extracted_dir"
      tar -xf "$tempd/pkg.tar.gz" -C "$extracted_dir"
      
    else
      echo "❌ --archived option requires URL to be .zip or .tar.gz format"
      exit 1
    fi

    # Look for dmg or pkg in extracted directory
    dmg_file=$(find "$extracted_dir" -name "*.dmg" -type f | head -1)
    pkg_file=$(find "$extracted_dir" -name "*.pkg" -type f | head -1)

    if [[ -n "$dmg_file" ]]; then
      # Process dmg file
      mountpoint="$tempd/mount"
      mkdir -p "$mountpoint"

      if [[ -n "$password" ]]; then
        echo "$password" | hdiutil attach "$dmg_file" -mountpoint "$mountpoint" -quiet -stdinpass
      else
        hdiutil attach "$dmg_file" -mountpoint "$mountpoint" -quiet
      fi

      if compgen -G "$mountpoint"/*.app > /dev/null; then
        copy_app "$mountpoint" "$target_path"
      elif compgen -G "$mountpoint"/*.pkg > /dev/null; then
        pkgfile=$(ls "$mountpoint"/*.pkg | head -1)
        sudo installer -pkg "$pkgfile" -target /
      else
        echo "❌ No .app or .pkg found in dmg"
        hdiutil detach "$mountpoint" -quiet || true
        rm -rf "$tempd"
        exit 1
      fi

      hdiutil detach "$mountpoint" -quiet || true

    elif [[ -n "$pkg_file" ]]; then
      # Process pkg file
      sudo installer -pkg "$pkg_file" -target /

    else
      echo "❌ No .dmg or .pkg found in extracted archive"
      rm -rf "$tempd"
      exit 1
    fi

  elif [[ $url == *.dmg || $type == "dmg" ]]; then
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
      copy_app "$mountpoint" "$target_path"
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
    copy_app "$tempd/apps" "$target_path"

  elif [[ $url == *.tar.gz || $type == "tar.gz" ]]; then
    echo "Downloading $url to $tempd/pkg.tar.gz..."
    wget -q --show-progress "$url" -O "$tempd/pkg.tar.gz"
    tar -xf "$tempd/pkg.tar.gz" -C "$tempd/apps"
    copy_app "$tempd/apps" "$target_path"

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
