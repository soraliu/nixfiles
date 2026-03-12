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

# 检测操作系统
OS=$(uname -s)

# 根据操作系统选择合适的链接路径
if [ "$OS" = "Darwin" ]; then
  # macOS: 优先使用 /usr/local/bin，这是 Homebrew 的标准路径
  path_to_just_link=/usr/local/bin/just
  # 确保 /usr/local/bin 存在
  if [ ! -d /usr/local/bin ]; then
    echo "Info: Creating /usr/local/bin directory"
    sudo mkdir -p /usr/local/bin
  fi
else
  # Linux: 优先使用 /usr/local/bin，如果不存在则使用 /usr/bin
  path_to_just_link=/usr/local/bin/just
  if [ ! -d /usr/local/bin ]; then
    path_to_just_link=/usr/bin/just
  fi
fi

if [ -f ${path_to_just_link} ]; then
  echo "Info: just has already linked at ${path_to_just_link}! Skip."
else
  # 创建符号链接
  echo "Info: Link ${path_to_just_bin} -> ${path_to_just_link}"
  if sudo ln -sf ${path_to_just_bin} ${path_to_just_link}; then
    echo "Info: Successfully linked just to ${path_to_just_link}"
  else
    echo "Error: Failed to create symbolic link. Please check permissions."
    echo "You can manually add ${path_to_just_bin} to your PATH"
    exit 1
  fi
fi
