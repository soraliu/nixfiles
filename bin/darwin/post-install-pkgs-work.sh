#!/usr/bin/env bash

set -e

source ./install-dmg.util.sh
source ./install.util.sh

install_dmg -n 'Google Drive.app' -u 'https://dl.google.com/drive-file-stream/GoogleDrive.dmg'
install_dmg -n 'Karabiner-Elements.app' -u 'https://github.com/pqrs-org/Karabiner-Elements/releases/download/v15.3.0/Karabiner-Elements-15.3.0.dmg' &
install_dmg -n 'Raycast.app' -u 'https://releases.raycast.com/download' -t 'dmg' &
install_dmg -n 'Caffeine.app' -u 'https://drive.home.soraliu.dev/dav/software/darwin/Caffeine/1.1.3/Caffeine.dmg' &
install_dmg -n 'Proxyman.app' -u 'https://github.com/ProxymanApp/Proxyman/releases/download/5.1.1/Proxyman_5.1.1.dmg' &
install_dmg -n 'Arc.app' -u 'https://releases.arc.net/release/Arc-latest.dmg' &
install_dmg -n 'Telegram.app' -u 'https://telegram.org/dl/desktop/mac' -t 'dmg' &
install_dmg -n 'Discord.app' -u 'https://discord.com/api/download?platform=osx' -t 'dmg' &
install_dmg -n '网易有道翻译.app' -u 'https://codown.youdao.com/cidian/download/MacDict.dmg' &
install_dmg -n 'KeyClu.app' -u 'https://github.com/Anze/KeyCluCask/releases/download/v0.25/KeyClu_v0.25.dmg' &
install_dmg -n 'Google Chrome.app' -u 'https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg' &
install_dmg -n 'Vysor.app' -u 'https://nuts.vysor.io/download/osx' -t 'dmg' &
install_dmg -n 'iTerm.app' -u 'https://iterm2.com/downloads/stable/iTerm2-3_5_4.zip' &
install_dmg -n 'CompressX.app' -u 'https://drive.home.soraliu.dev/dav/software/darwin/CompressX/1.14/CompressX-1.14.dmg' &
install_dmg -n 'Pearcleaner.app' -u 'https://github.com/alienator88/Pearcleaner/releases/download/4.4.3/Pearcleaner.dmg' &
install_dmg -n 'CleanShot X.app' -u 'https://drive.home.soraliu.dev/dav/software/darwin/CleanShotX/4.7.6/CleanShotX.dmg' &
install -n 'Squirrel.app' -u 'https://github.com/rime/squirrel/releases/download/1.0.3/Squirrel-1.0.3.pkg' &


if $(uname -m | grep -q 'arm'); then
  install_dmg -n 'Docker.app' -u 'https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64' -t 'dmg' &
  install_dmg -n 'Synergy.app' -u 'https://symless.com/synergy/synergy/api/download/synergy-macOS_arm64-v3.0.80.1-rc3.dmg' &
  install_dmg -n 'Todoist.app' -u 'https://todoist.com/mac_app?arch=arm' -t 'dmg' &
  install_dmg -n 'Wireshark.app' -u 'https://2.na.dl.wireshark.org/osx/Wireshark%204.2.6%20Arm%2064.dmg' &
  install_dmg -n 'Anki.app' -u 'https://github.com/ankitects/anki/releases/download/25.02.6/anki-25.02.6-mac-apple-qt6.dmg' &
elif $(uname -m | grep -q 'x86'); then
  install_dmg -n 'Docker.app' -u 'https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-amd64' -t 'dmg' &
  install_dmg -n 'Synergy.app' -u 'https://symless.com/synergy/synergy/api/download/synergy-macOS_x64-v3.0.80.1-rc3.dmg' &
  install_dmg -n 'Todoist.app' -u 'https://todoist.com/mac_app?arch=x64' -t 'dmg' &
  install_dmg -n 'Wireshark.app' -u 'https://2.na.dl.wireshark.org/osx/Wireshark%204.2.6%20Intel%2064.dmg' &
  install_dmg -n 'Anki.app' -u 'https://github.com/ankitects/anki/releases/download/25.02.6/anki-25.02.6-mac-intel-qt6.dmg' &
else
  echo "Error: Unknown arch $(uname -m)"
fi

wait
