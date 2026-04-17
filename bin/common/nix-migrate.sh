#!/usr/bin/env bash
# 从 upstream Nix (官方 installer 或老 DNI) 平滑迁移到 Determinate Nix 3.x
#
# 支持平台:
# - macOS: 删除 "Nix Store" APFS volume → /etc 清理 → Determinate.pkg 接管
# - Linux (Ubuntu WSL 等 non-NixOS): 先尝试 Determinate installer in-place
#                                    失败则手动卸载 upstream → 重装
#
# 不适用:
# - NixOS / NixOS-WSL: 已 Nix-native, 走 determinate.nixosModules.default
#   通过 nixos-rebuild switch 升级即可 (switch 后 nix.package = determinate)
#
# ⚠ 警告: /nix/store 会被清空! 一次 switch 重建 15-30 min (依网速和 closure 规模).
#
# 使用:
#   ./bin/common/nix-migrate.sh         # 自动探测平台 + 迁移
#   ./bin/common/nix-migrate.sh --dry   # 只打印计划, 不执行
#
# 执行顺序推荐:
#   1) ./bin/common/nix-migrate.sh      # 本脚本
#   2) 新开 shell
#   3) ./bin/common/pre-init-nix.sh     # 写 bootstrap ~/.config/nix/nix.conf
#   4) just switch-darwin <user>        # 或 switch-nixos <profile> / switch-ubuntu <profile>

set -e

# ---------- helpers ----------
cyan() { printf '\033[36m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
red() { printf '\033[31m%s\033[0m' "$*"; }
log() { printf '\n%s %s\n' "$(cyan '[nix-migrate]')" "$*"; }
warn() { printf '\n%s %s\n' "$(yellow '[warn]')" "$*"; }
die() { printf '\n%s %s\n' "$(red '[fatal]')" "$*" >&2; exit 1; }

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry|--dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '1,30p' "$0"; exit 0 ;;
    *) die "unknown arg: $1" ;;
  esac
done

run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry] %s\n' "$*"
  else
    eval "$@"
  fi
}

# elevate to root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = "0" ]; then
  warn "需要 root, 自动 sudo 提权..."
  exec sudo -E /bin/bash "$0" "$@"
fi

OS="$(uname)"

# =====================================================================
#                             macOS branch
# =====================================================================
migrate_macos() {
  log "平台: macOS"

  # step A: 定位 Nix Store volume
  log "step A: 定位 Nix Store APFS volume"
  local volume_id
  volume_id="$(diskutil list | awk '/APFS Volume Nix Store/ {print $NF; exit}')"
  if [ -z "$volume_id" ]; then
    warn "未发现 Nix Store volume. 可能已删除, 直接进入安装阶段."
  else
    log "  volume id: $volume_id"
  fi

  # step B: unmount (如果挂载)
  if [ -n "$volume_id" ]; then
    log "step B: force unmount $volume_id (幂等)"
    run "diskutil unmount force '$volume_id' 2>&1 || echo '  (already unmounted)'"
  fi

  # step C: launchctl bootout (非致命)
  log "step C: 卸载 nix 相关 launchd 服务 (非致命)"
  run "launchctl bootout system/org.nixos.darwin-store 2>/dev/null || echo '  (darwin-store not loaded)'"
  run "launchctl bootout system/org.nixos.nix-daemon 2>/dev/null || echo '  (nix-daemon not loaded)'"

  # step D: 删除 volume
  if [ -n "$volume_id" ]; then
    log "step D: diskutil apfs deleteVolume $volume_id (/nix/store 清空)"
    run "diskutil apfs deleteVolume '$volume_id'"
    if [ "$DRY_RUN" = "0" ]; then
      if diskutil list 2>/dev/null | grep -q "APFS Volume Nix Store"; then
        die "volume 删除失败, 手动介入: sudo diskutil apfs deleteVolume <id>"
      fi
      log "  ✓ volume 已删"
    fi
  fi

  # step E: 清理 /etc/synthetic.conf 的 nix 行
  log "step E: 清理 /etc/synthetic.conf"
  if [ -f /etc/synthetic.conf ]; then
    run "sed -i.bak '/^nix\\s*$/d' /etc/synthetic.conf"
    # 空文件则删
    if [ "$DRY_RUN" = "0" ] && ! grep -q '[^[:space:]]' /etc/synthetic.conf 2>/dev/null; then
      rm -f /etc/synthetic.conf
      log "  已删除空 /etc/synthetic.conf"
    fi
  fi

  # step F: 清理 /etc/fstab 的 /nix 行
  log "step F: 清理 /etc/fstab"
  if [ -f /etc/fstab ]; then
    run "sed -i.bak '/\\/nix apfs/d' /etc/fstab"
    if [ "$DRY_RUN" = "0" ] && ! grep -q '[^[:space:]]' /etc/fstab 2>/dev/null; then
      rm -f /etc/fstab
      log "  已删除空 /etc/fstab"
    fi
  fi

  # step G: 清理 /etc/nix/ 遗留
  log "step G: 清理 /etc/nix/ (nix.conf / registry.json / .before-nix-darwin)"
  run "rm -rf /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin /etc/nix/registry.json"

  # step H: 清理用户层 broken symlinks
  log "step H: 清理 ~/.nix-profile ~/.nix-defexpr ~/.nix-channels"
  local target_user="${SUDO_USER:-$USER}"
  run "su - '$target_user' -c 'rm -rf \"\$HOME/.nix-profile\" \"\$HOME/.nix-defexpr\" \"\$HOME/.nix-channels\" 2>/dev/null || true'"

  # step I: 下载并安装 Determinate.pkg (官方推荐, 对 macOS 原生接管更可靠)
  log "step I: 安装 Determinate.pkg"
  run "curl -fsSL -o /tmp/Determinate.pkg 'https://install.determinate.systems/determinate-pkg/stable/Universal'"
  run "installer -pkg /tmp/Determinate.pkg -target /"
}

# =====================================================================
#                             Linux branch
# =====================================================================
migrate_linux() {
  log "平台: Linux ($(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}"))"

  # 检测是否 NixOS
  if [ -f /etc/NIXOS ] || [ -f /etc/nixos/configuration.nix ]; then
    warn "检测到 NixOS, 此脚本不适用."
    warn "NixOS 请通过 nixos-rebuild switch (已集成 determinate.nixosModules.default) 升级."
    return 1
  fi

  # step A: 尝试 Determinate installer 直接 in-place 接管 (Linux 支持度较好)
  log "step A: 尝试 Determinate installer in-place 接管"
  if run "curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm"; then
    log "  ✓ Determinate installer 成功接管"
    return 0
  fi

  warn "  in-place 接管失败, 回退到手动卸载 upstream 再重装"

  # step B: 停止 & 卸载 upstream nix-daemon (systemd)
  log "step B: 停止 upstream nix-daemon (systemd)"
  run "systemctl stop nix-daemon.service 2>/dev/null || true"
  run "systemctl stop nix-daemon.socket 2>/dev/null || true"
  run "systemctl disable nix-daemon.service 2>/dev/null || true"
  run "systemctl disable nix-daemon.socket 2>/dev/null || true"
  run "rm -f /etc/systemd/system/nix-daemon.service /etc/systemd/system/nix-daemon.socket"
  run "systemctl daemon-reload"
  run "systemctl reset-failed"

  # step C: 清理 /etc/profile.d/nix*.sh 等 shell hook
  log "step C: 清理 shell profile hooks"
  run "rm -f /etc/profile.d/nix.sh /etc/profile.d/nix-daemon.sh"
  # 还可能注入到 /etc/bash.bashrc /etc/zshrc; 保守只 undo installer backup 的 .backup-before-nix
  for f in /etc/bashrc /etc/zshrc /etc/bash.bashrc /etc/zsh/zshrc; do
    if [ -f "$f.backup-before-nix" ]; then
      run "mv '$f.backup-before-nix' '$f'"
      log "  restored $f from .backup-before-nix"
    fi
  done

  # step D: 清理 nixbld 用户 / 组 (upstream multi-user 模式创建 1~32)
  log "step D: 清理 nixbld 组和成员"
  for i in $(seq 1 32); do
    run "userdel nixbld$i 2>/dev/null || true"
  done
  run "groupdel nixbld 2>/dev/null || true"

  # step E: 清理 /nix /etc/nix
  log "step E: rm -rf /nix /etc/nix (⚠ /nix/store 清空)"
  run "rm -rf /nix /etc/nix"

  # step F: 清理用户层
  log "step F: 清理用户层 ~/.nix-*"
  local target_user="${SUDO_USER:-$USER}"
  run "su - '$target_user' -c 'rm -rf \"\$HOME/.nix-profile\" \"\$HOME/.nix-defexpr\" \"\$HOME/.nix-channels\" 2>/dev/null || true'"
  # root 也有时会装到 /root/.nix-*
  run "rm -rf /root/.nix-profile /root/.nix-defexpr /root/.nix-channels 2>/dev/null || true"

  # step G: 重新安装 Determinate
  log "step G: 安装 Determinate Nix"
  run "curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm"
}

# ---------- main ----------
case "$OS" in
  Darwin) migrate_macos ;;
  Linux)  migrate_linux ;;
  *) die "不支持的平台: $OS" ;;
esac

log "迁移完成 ✓"
cat <<'EOF'

下一步:

  1) 新开一个 Terminal (旧 shell 的 ~/.nix-profile 已失效)
  2) 确认 Determinate 已装:

       nix --version                       # 应含 "Determinate Nix"
       nix config show | grep lazy-trees   # 应为 true

  3) 写入 user-level bootstrap ~/.config/nix/nix.conf (含 community cache / /tmp/.age):

       ~/.nixfiles/bin/common/pre-init-nix.sh

  4) 首次 switch (会重建整个 closure, 15-30 min):

       cd ~/.nixfiles
       just switch-darwin soraliu       # macOS
       # 或
       just switch-ubuntu ide           # Ubuntu WSL

EOF
