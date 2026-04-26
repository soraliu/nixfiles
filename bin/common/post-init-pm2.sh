#!/usr/bin/env bash
set -e

# pm2 startup 生成 OS 启动时的 pm2 resurrect 脚本
# 主要用于 Linux Ubuntu，以 root 用户运行
# switch-home 后当前 shell 不会立刻加载 sessionPath，需用绝对路径访问 pm2

PM2_BIN="${HOME}/.volta/bin/pm2"

if [ ! -x "$PM2_BIN" ]; then
  echo "[post-init-pm2] pm2 not found at $PM2_BIN, skipping"
  exit 0
fi

echo "[post-init-pm2] Running: sudo $PM2_BIN startup"
sudo "$PM2_BIN" startup

echo "[post-init-pm2] Running: $PM2_BIN save"
"$PM2_BIN" save
