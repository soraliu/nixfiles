#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/install-dmg.util.sh
source $SCRIPT_DIR/install.util.sh

install_dmg -n '网易有道翻译.app' -u 'https://codown.youdao.com/cidian/download/MacDict.dmg' &
install_dmg -n 'KeyClu.app' -u 'https://github.com/Anze/KeyCluCask/releases/download/v0.25/KeyClu_v0.25.dmg' &
install_dmg -n 'Vysor.app' -u 'https://nuts.vysor.io/download/osx' -t 'dmg' &
install_dmg -n 'CompressX.app' -u 'https://drive.home.soraliu.dev/dav/software/darwin/CompressX/1.14/CompressX-1.14.dmg' &
install_dmg -n 'Pearcleaner.app' -u 'https://github.com/alienator88/Pearcleaner/releases/download/4.4.3/Pearcleaner.dmg' &
install_dmg -n 'CleanShot X.app' -u 'https://drive.home.soraliu.dev/dav/software/darwin/CleanShotX/4.8.7/CleanShotX.dmg' &
install -n 'Obsidian.app' -u 'https://github.com/obsidianmd/obsidian-releases/releases/download/v1.10.6/Obsidian-1.10.6.dmg' -t 'dmg' &
install -n 'ClashX.Meta.app' -u 'https://github.com/MetaCubeX/ClashX.Meta/releases/download/v1.4.29/ClashX.Meta.zip' -t 'zip' &

if $(uname -m | grep -q 'arm'); then
  install_dmg -n 'Synergy.app' -u 'https://symless.com/synergy/synergy/api/download/synergy-macOS_arm64-v3.0.80.1-rc3.dmg' &
  install_dmg -n 'Todoist.app' -u 'https://todoist.com/mac_app?arch=arm' -t 'dmg' &
  install_dmg -n 'Anki.app' -u 'https://github.com/ankitects/anki/releases/download/25.02.6/anki-25.02.6-mac-apple-qt6.dmg' &
elif $(uname -m | grep -q 'x86'); then
  install_dmg -n 'Synergy.app' -u 'https://symless.com/synergy/synergy/api/download/synergy-macOS_x64-v3.0.80.1-rc3.dmg' &
  install_dmg -n 'Todoist.app' -u 'https://todoist.com/mac_app?arch=x64' -t 'dmg' &
  install_dmg -n 'Anki.app' -u 'https://github.com/ankitects/anki/releases/download/25.02.6/anki-25.02.6-mac-intel-qt6.dmg' &
else
  echo "Error: Unknown arch $(uname -m)"
fi

wait
