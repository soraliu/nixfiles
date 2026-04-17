#!/usr/bin/env bash
# 全新机器上 bootstrap Determinate Nix 3.x + 写 nix.conf (user-level + VPS 兜底 system-level)
#
# 配置分层 (方案 A):
# - pkgs/determinate/default.nix → /etc/nix/nix.custom.conf (Darwin / NixOS 有 module 的场景)
#   • 管 cross-host 不变量: trusted-users, lazy-trees, extra-sandbox-paths, pubkey
# - 本脚本 → $HOME/.config/nix/nix.conf + $root_home/.config/nix/nix.conf
#   • 管 per-host 偏好: extra-substituters (region) + bootstrap 兜底 (首次 switch 前生效)
# - 本脚本 → /etc/nix/nix.custom.conf (仅 pure Linux VPS, 无 nix-darwin/NixOS 场景)
#   • 补 2 项 gap: extra-sandbox-paths, extra-trusted-public-keys
#
# 为什么同时写 $HOME 和 $root_home 的 user-level nix.conf:
# - sudo 下 $HOME 被重置 (macOS → /var/root, Linux → /root), nix 读 root 的 user-level
# - 验证过: /var/root/.config/nix/nix.conf 的 extra-substituters 能被 sudo nix config show 读到
# - sudo (root) 是 trusted client, 能把 extra-substituters/sandbox-paths 透传给 daemon
#
# 为什么 user-level 不写 trusted-users / lazy-trees:
# - trusted-users: 只在 daemon 启动时读 /etc/nix/nix.conf 生效, user-level 被忽略 (Nix 安全策略)
# - lazy-trees: Determinate 3.5.2+ 默认 true, 不写防漂移
#
# 假设:
# - /nix 不存在, 或已由 bin/common/nix-migrate.sh 清理干净
# - 目标机器走 Determinate 3.x (非 upstream Nix)
#
# 不处理: 旧 upstream Nix 迁移. 如果机器已有 upstream Nix, 先跑:
#   ./bin/common/nix-migrate.sh
#
# 使用:
#   ./bin/common/pre-init-nix.sh                # 默认 region=global
#   ./bin/common/pre-init-nix.sh --region cn    # 加中国镜像 (清华/交大/USTC)

set -e

# ---------- args ----------
region=global
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region) region="$2"; shift 2 ;;
    -h|--help) sed -n '1,31p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

# substituter + pubkey 成对定义: 每个 region 块内 extra_substituters 和 extra_trusted_public_keys 并排,
# 保证新增 region 或新增 substituter 时必须同时考虑对应 pubkey, 避免两边漂移导致签名验证失败.
#
# cn mirror 注意事项:
# - nix-channels mirror 是 read-only passthrough, narinfo 里 Sig: 就是 cache.nixos.org-1 原签,
#   mirror 本身不重签, 所以仅需 cache.nixos.org-1 pubkey (不需 tuna-1 / sjtu-1 / ustc-1 之类)
# - priority=10.. 让 cn mirror 排在 cache.nixos.org (default 30) 前面, 避免 extra- 默认拼在列表末尾
case "$region" in
  global)
    extra_substituters="https://cache.nixos.org https://nix-community.cachix.org"
    extra_trusted_public_keys="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ;;
  cn)
    extra_substituters="https://mirrors.ustc.edu.cn/nix-channels/store?priority=10 https://mirror.sjtu.edu.cn/nix-channels/store?priority=11 https://cache.nixos.org https://nix-community.cachix.org"
    # 与 global 相同 (mirror passthrough 共用上游签名)
    extra_trusted_public_keys="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ;;
  *)
    echo "unknown region: $region (expected: global | cn)"; exit 1
    ;;
esac

# ---------- 平台常量 ----------
os_type="$(uname)"

# sudo 下 $HOME 被重置成 root 的默认 home, 跨平台定位:
case "$os_type" in
  Darwin) root_home="/var/root" ;;
  Linux)  root_home="/root" ;;
  *) echo "Error: 不支持的平台: $os_type"; exit 1 ;;
esac

# ---------- 1) 安装 Determinate Nix (平台分发) ----------
if command -v nix >/dev/null 2>&1 && nix --version 2>/dev/null | grep -qi determinate; then
  echo "Info: Determinate Nix 已安装 ($(nix --version))"
else
  case "$os_type" in
    Darwin)
      echo "Info: macOS — 使用 Determinate.pkg (官方推荐路径)"
      curl -fsSL -o /tmp/Determinate.pkg "https://install.determinate.systems/determinate-pkg/stable/Universal"
      sudo installer -pkg /tmp/Determinate.pkg -target /
      ;;
    Linux)
      echo "Info: Linux — 使用 Determinate 一键安装器"
      curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
      ;;
  esac
fi

# ---------- 2) 写 user-level nix.conf (双目标: $HOME + $root_home) ----------
# 同时写两份, 内容完全一致:
# - $HOME/.config/nix/nix.conf       → 当前 user 跑 nix build / flake / nh 交互
# - $root_home/.config/nix/nix.conf  → sudo 下 HOME 被重置, root 作为 trusted client 读这份
#
# 覆盖式写入 (幂等, 支持 region 切换 cn ↔ global 干净). 手动修改会丢.

# sops 解密 sandbox 路径需提前创建 (extra-sandbox-paths 会引用)
mkdir -p /tmp/.age

write_user_nix_conf() {
  local target_path="$1"
  local use_sudo="$2"  # "sudo" or ""

  local runner=""
  [ "$use_sudo" = "sudo" ] && runner="sudo"

  $runner mkdir -p "$(dirname "$target_path")"
  $runner tee "$target_path" > /dev/null <<EOF
# Managed by bin/common/pre-init-nix.sh (region=$region)
# 每次运行本脚本会完整覆盖此文件. 手动修改会被下次运行覆盖.
#
# 持久自定义配置请改:
# - Darwin / NixOS: pkgs/determinate/default.nix (customSettings → /etc/nix/nix.custom.conf)
# - Pure Ubuntu VPS: /etc/nix/nix.custom.conf (本脚本在 VPS 场景写入)
experimental-features = nix-command flakes
extra-substituters = $extra_substituters
extra-trusted-public-keys = $extra_trusted_public_keys
extra-sandbox-paths = /tmp/.age
# download-buffer-size:
# - Determinate 3.17 默认 1 MB (过小, 大 nar 下载时 pipeline stall)
# - upstream Nix 默认 64 MB = 67108864
# - buffer 小会把 socket 接收速度耦合到磁盘/解压消费速度, 链路吃不满
# - 设为 upstream default (64 MB), client trusted (sudo) 时会透传给 daemon 生效
download-buffer-size = 67108864
EOF
  echo "Info: wrote $target_path"
}

write_user_nix_conf "$HOME/.config/nix/nix.conf" ""
write_user_nix_conf "$root_home/.config/nix/nix.conf" "sudo"

# ---------- 3) 有条件写 system-level /etc/nix/nix.custom.conf (VPS fallback) ----------
# 场景判定:
# - Darwin (macOS)           → 走 nix-darwin, customSettings 由 pkgs/determinate/default.nix 管. Skip.
# - NixOS (/etc/nixos 存在)  → 走 NixOS, 同上. Skip.
# - 其他 Linux (纯 Ubuntu / Debian / etc) → 无 module 管 /etc/nix/nix.custom.conf, 本脚本补 2 项 gap.
#
# 为什么只补 2 项 (非完整 customSettings):
# - trusted-users: Determinate installer 默认 "root @wheel", 单用户 VPS 已够
# - lazy-trees: Determinate 3.5.2+ 默认 true, 不需写

needs_vps_bootstrap="no"
if [ "$os_type" = "Linux" ] && [ ! -d /etc/nixos ]; then
  needs_vps_bootstrap="yes"
fi

if [ "$needs_vps_bootstrap" = "yes" ]; then
  echo "Info: 纯 Linux VPS (无 NixOS) — 写 /etc/nix/nix.custom.conf 补 sandbox + pubkey"

  sudo tee /etc/nix/nix.custom.conf > /dev/null <<'EOF'
# Managed by bin/common/pre-init-nix.sh (pure Linux VPS fallback)
# Darwin / NixOS 场景不会执行此写入, 由 pkgs/determinate/default.nix 的 customSettings 管理.
#
# 不写 trusted-users (Determinate installer 默认 "root @wheel" 对单用户 VPS 足够).
# 不写 lazy-trees (Determinate 3.5.2+ 默认启用).
extra-sandbox-paths = /tmp/.age
extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
# download-buffer-size: 覆盖 Determinate 默认 1 MB, 对齐 upstream 64 MB (减少大 nar 下载时 pipeline stall)
download-buffer-size = 67108864
EOF

  # Determinate 的 /etc/nix/nix.conf 默认 !include nix.custom.conf, 改完需重启 daemon
  echo "Info: 重启 nix-daemon 让 extra-sandbox-paths 对 build sandbox 生效"
  if sudo systemctl restart nix-daemon 2>/dev/null; then
    echo "Info: systemctl restart nix-daemon 成功"
  else
    echo "Warn: systemctl 不可用或服务名不匹配, 请手动重启 nix-daemon"
  fi
else
  echo "Info: Darwin / NixOS — /etc/nix/nix.custom.conf 由 pkgs/determinate/default.nix 管, skip"
fi

# ---------- 4) 软链 nix 到 /usr/local/bin (便于脚本通过固定路径调用) ----------
path_to_nix_link=/usr/local/bin
[ -d "$path_to_nix_link" ] || path_to_nix_link=/usr/bin

if [ -f "${path_to_nix_link}/nix" ]; then
  echo "Info: ${path_to_nix_link}/nix 已存在, skip"
else
  for candidate in \
    "$HOME/.nix-profile/bin" \
    /nix/var/nix/profiles/default/bin \
    /run/current-system/sw/bin
  do
    if [ -e "$candidate/nix" ]; then
      sudo ln -sf "$candidate/nix" "${path_to_nix_link}/nix"
      echo "Info: linked $candidate/nix → ${path_to_nix_link}/nix"
      break
    fi
  done
fi

echo
echo "Info: pre-init-nix.sh 完成 (region=$region)"
echo "      新开 shell 后可 just switch-darwin <user> / just switch-home <profile>"
