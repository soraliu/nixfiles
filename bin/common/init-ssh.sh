#!/usr/bin/env bash
set -euo pipefail

# 将本机 SSH 公钥推送到远程节点，实现免密 SSH 登录
#
# 自动检测远程环境：
#   - pm2 管理的 sshd → authorized_keys 部署到 ~/.config/ssh/authorized_keys
#   - WSL / 标准 Ubuntu 系统 sshd → authorized_keys 部署到 ~/.ssh/authorized_keys
#
# 使用:
#   ./bin/common/init-ssh.sh                        # 默认 root@10.1.1.1
#   ./bin/common/init-ssh.sh root@primary.soraliu.dev
#   SSH_PASS=password ./bin/common/init-ssh.sh root@primary.soraliu.dev  # 非交互式
#
# 环境变量:
#   SSH_PASS    - 远程密码（可选，未设置时交互式提示输入）
#   SSH_PUB_KEY - 本地公钥路径（可选，默认自动检测）

TARGET="${1:-root@10.1.1.1}"

# --- 查找本地公钥 ---
find_pub_key() {
  for key in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
    if [ -f "$key" ]; then
      echo "$key"
      return 0
    fi
  done
  return 1
}

PUB_KEY_PATH="${SSH_PUB_KEY:-$(find_pub_key)}"

if [ -z "$PUB_KEY_PATH" ] || [ ! -f "$PUB_KEY_PATH" ]; then
  echo "Error: SSH public key not found. Generate one first:"
  echo "  ssh-keygen -t ed25519 -C '$USER@$(hostname)'"
  exit 1
fi

FINGERPRINT=$(ssh-keygen -l -f "$PUB_KEY_PATH" 2>/dev/null | awk '{print $2}')
echo "Using public key: $PUB_KEY_PATH ($FINGERPRINT)"

# --- 构建 SSH 基础参数 ---
SSH_BASE_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"

# --- ssh_run: 统一的远程命令执行函数 ---
ssh_run() {
  if [ -n "${SSH_PASS:-}" ] && command -v sshpass >/dev/null 2>&1; then
    sshpass -p "$SSH_PASS" ssh $SSH_BASE_OPTS "$TARGET" "$@"
  else
    ssh $SSH_BASE_OPTS "$TARGET" "$@"
  fi
}

# --- 验证远程可达 ---
echo "Connecting to $TARGET ..."
if ! ssh_run "echo ok" 2>/dev/null | grep -q "ok"; then
  echo "Error: Cannot SSH to $TARGET (host unreachable or wrong password)"
  exit 1
fi
echo "SSH connectivity OK."

# --- 检测远程环境，确定 authorized_keys 路径 ---
echo "Detecting remote environment ..."
REMOTE_AUTH_PATH=$(ssh_run bash -s <<'DETECT'
# 优先检测 pm2 管理的 sshd
if command -v pm2 >/dev/null 2>&1 && pm2 pid sshd >/dev/null 2>&1; then
  echo "pm2"
  exit 0
fi

# 检测 WSL 环境
if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
  echo "wsl"
  exit 0
fi

# 标准 Linux 系统 sshd
echo "system"
DETECT
)

case "$REMOTE_AUTH_PATH" in
  pm2)    REMOTE_AUTH_PATH=".config/ssh/authorized_keys" ;;
  *)      REMOTE_AUTH_PATH=".ssh/authorized_keys" ;;
esac

REMOTE_KEY_DIR=$(dirname "$REMOTE_AUTH_PATH")
echo "Remote authorized_keys path: ~/$REMOTE_AUTH_PATH"

# --- 部署公钥 ---
# 先通过管道将公钥文件传到远程临时文件，再在远程追加到 authorized_keys
# 这样避免了公钥内容在 shell 参数/heredoc 传递中被分词截断
echo "Deploying public key to $TARGET:~/$REMOTE_AUTH_PATH ..."
TMP_REMOTE_KEY="/tmp/init-ssh-pubkey-$$.pub"

# 上传公钥到远程临时文件
ssh_run "cat > $TMP_REMOTE_KEY" < "$PUB_KEY_PATH"

# 远程执行追加逻辑
DEPLOY_RESULT=$(ssh_run bash -s -- "$REMOTE_KEY_DIR" "$REMOTE_AUTH_PATH" "$TMP_REMOTE_KEY" "$FINGERPRINT" <<'REMOTE_SCRIPT'
  KEY_DIR="$1"
  AUTH_PATH="$2"
  TMP_KEY="$3"
  FP="$4"

  mkdir -p "$HOME/$KEY_DIR"
  chmod 700 "$HOME/$KEY_DIR"

  AUTH_FILE="$HOME/$AUTH_PATH"

  if [ -f "$AUTH_FILE" ] && grep -qF "$FP" "$AUTH_FILE" 2>/dev/null; then
    echo "KEY_EXISTS"
    rm -f "$TMP_KEY"
    exit 0
  fi

  cat "$TMP_KEY" >> "$AUTH_FILE"
  chmod 600 "$AUTH_FILE"
  rm -f "$TMP_KEY"
  echo "KEY_DEPLOYED"
REMOTE_SCRIPT
)

case "$DEPLOY_RESULT" in
  *KEY_EXISTS*)
    echo "Public key already exists in ~/$REMOTE_AUTH_PATH, skipping."
    ;;
  *KEY_DEPLOYED*)
    echo "Public key deployed to ~/$REMOTE_AUTH_PATH."
    ;;
  *)
    echo "Error: Failed to deploy public key (output: $DEPLOY_RESULT)"
    exit 1
    ;;
esac

# --- 重启 sshd（仅 pm2 管理时需要） ---
if [ "$REMOTE_AUTH_PATH" = ".config/ssh/authorized_keys" ]; then
  echo "Restarting remote sshd (pm2) ..."
  ssh_run "pm2 restart sshd" >/dev/null 2>&1 || true
  echo "Remote sshd restarted."
fi

# --- 验证公钥登录 ---
echo "Verifying public key authentication ..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET" "echo ok" >/dev/null 2>&1; then
  echo "Public key authentication OK."
else
  echo "Warning: Public key authentication failed. Check remote sshd_config AuthorizedKeysFile path."
fi

echo "Done. Try: ssh $TARGET"
