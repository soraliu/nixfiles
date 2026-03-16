#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/install-dmg.util.sh
source $SCRIPT_DIR/install.util.sh

install_dmg -n 'Raycast.app' -u 'https://releases.raycast.com/download' -t 'dmg' &
install_dmg -n 'Google Drive.app' -u 'https://dl.google.com/drive-file-stream/GoogleDrive.dmg'
install_dmg -n 'Karabiner-Elements.app' -u 'https://github.com/pqrs-org/Karabiner-Elements/releases/download/v15.3.0/Karabiner-Elements-15.3.0.dmg' &
install_dmg -n 'Caffeine.app' -u 'https://drive.home.soraliu.dev/dav/software/darwin/Caffeine/1.1.3/Caffeine.dmg' &
install_dmg -n 'Proxyman.app' -u 'https://github.com/ProxymanApp/Proxyman/releases/download/5.1.1/Proxyman_5.1.1.dmg' &
install_dmg -n 'Arc.app' -u 'https://releases.arc.net/release/Arc-latest.dmg' &
install_dmg -n 'Telegram.app' -u 'https://telegram.org/dl/desktop/mac' -t 'dmg' &
install_dmg -n 'Discord.app' -u 'https://discord.com/api/download?platform=osx' -t 'dmg' &
install_dmg -n 'Google Chrome.app' -u 'https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg' &
install_dmg -n 'iTerm.app' -u 'https://iterm2.com/downloads/stable/iTerm2-3_5_4.zip' &
install -n '/Library/Input Methods/Squirrel.app' -u 'https://github.com/rime/squirrel/releases/download/1.1.2/Squirrel-1.1.2.pkg' &


if $(uname -m | grep -q 'arm'); then
  install_dmg -n 'Docker.app' -u 'https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64' -t 'dmg' &
  install_dmg -n 'Deskflow.app' -u 'https://github.com/deskflow/deskflow/releases/download/v1.26.0/deskflow-1.26.0-macos-arm64.dmg' &
  install_dmg -n 'Wireshark.app' -u 'https://2.na.dl.wireshark.org/osx/Wireshark%204.2.6%20Arm%2064.dmg' &
  install_dmg -n 'DBeaver.app' -u 'https://dbeaver.io/files/dbeaver-ce-latest-macos-aarch64.dmg' &
  install -n 'Apidog.app' -u 'https://file-assets.apidog.com/download/Apidog-macOS-arm64-latest.zip' -a -t 'dmg' &
elif $(uname -m | grep -q 'x86'); then
  install_dmg -n 'Docker.app' -u 'https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-amd64' -t 'dmg' &
  install_dmg -n 'Deskflow.app' -u 'https://github.com/deskflow/deskflow/releases/download/v1.26.0/deskflow-1.26.0-macos-x86_64.dmg' &
  install_dmg -n 'Wireshark.app' -u 'https://2.na.dl.wireshark.org/osx/Wireshark%204.2.6%20Intel%2064.dmg' &
  install_dmg -n 'DBeaver.app' -u 'https://dbeaver.io/files/dbeaver-ce-latest-macos-x86_64.dmg' &
  install -n 'Apidog.app' -u 'https://file-assets.apidog.com/download/Apidog-macOS-latest.zip' -a -t 'dmg' &
else
  echo "Error: Unknown arch $(uname -m)"
fi

wait
