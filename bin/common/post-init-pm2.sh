#!/usr/bin/env bash
set -e

# pm2 startup 生成 OS 启动时的 pm2 resurrect 脚本
# 主要用于 Linux Ubuntu，以 root 用户运行
# switch-home 后当前 shell 不会立刻加载 sessionPath，需用绝对路径访问 pm2
# 仅限 Linux：sudo pm2 startup 在 Darwin 上会生成 UserName=root 的 com.PM2 LaunchAgent，
# label 与用户级 com.PM2 plist 冲突，且其引用的 nix store pm2 路径被 GC 后变成死文件；
# darwin 的 pm2 已由 pkgs/pm2 activation 声明式管理。正向判断 Linux 而非排除 Darwin，
# 使 uname 异常（返回空值）时也走安全的跳过分支
if [ "$(uname -s)" != "Linux" ]; then
  echo "[post-init-pm2] non-Linux system detected, skipping (darwin pm2 is managed by pkgs/pm2 activation)"
  exit 0
fi

PM2_BIN="${HOME}/.volta/bin/pm2"

if [ ! -x "$PM2_BIN" ]; then
  echo "[post-init-pm2] pm2 not found at $PM2_BIN, skipping"
  exit 0
fi

echo "[post-init-pm2] Running: sudo $PM2_BIN startup"
sudo "$PM2_BIN" startup

echo "[post-init-pm2] Running: $PM2_BIN save"
"$PM2_BIN" save
