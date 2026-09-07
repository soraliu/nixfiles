# -------------------------------------------------------------------------------------------------------------------------------
# functions
# -------------------------------------------------------------------------------------------------------------------------------
herdr-layout-agent() {
  local path_to_cwd=${1:-$PWD}
  local label="$(basename "${path_to_cwd}")"
  local nvim="$HOME_PROFILE_DIRECTORY/bin/nvim"
  # 须在 herdr 会话内运行(HERDR_TAB_ID 由 pane 导出);否则先 'h' 进入
  if [ -z "${HERDR_TAB_ID:-}" ]; then
    echo "[!] not inside herdr; run 'h' first" >&2
    return 1
  fi
  local resp left right right2
  resp=$(herdr tab create --cwd "$path_to_cwd" --label "$label" --focus) || { echo "$resp" >&2; return 1; }
  left=$(printf '%s' "$resp" | jq -r '.result.root_pane.pane_id // empty')
  [ -z "$left" ] && { echo "[!] no root_pane.pane_id: $resp" >&2; return 1; }
  # 复刻 zellij agent 布局:左 50% nvim + 右上下各 25% shell
  right=$(herdr pane split "$left"  --direction right --ratio 0.5 --no-focus | jq -r '.result.pane.pane_id // empty')
  right2=$(herdr pane split "$right" --direction down  --ratio 0.5 --no-focus | jq -r '.result.pane.pane_id // empty')
  herdr pane run   "$left" "$nvim" >/dev/null 2>&1 || true
  herdr pane focus "$left"        >/dev/null 2>&1 || true
}

herdr-kill-sessions() {
  # 关停除 default 外的 herdr session(类比 zellij zko)
  # 注:JSON 路径 .result.sessions 以 `herdr session list --json` 实际输出为准,运行时核对
  local cur="${HERDR_SESSION:-default}"
  herdr session list --json 2>/dev/null \
    | jq -r '(.result.sessions // .sessions // [] | .[] | .name) // empty' 2>/dev/null \
    | sort -u \
    | while read -r name; do
        [ -n "$name" ] || continue
        [ "$name" != "default" ] || continue
        [ "$name" != "$cur" ] || continue
        herdr session stop "$name" >/dev/null 2>&1 || true
      done
}

proxy_on() {
  export http_proxy=http://127.0.0.1:7890
  export https_proxy=http://127.0.0.1:7890
  export no_proxy=127.0.0.1,localhost
  export HTTP_PROXY=http://127.0.0.1:7890
  export HTTPS_PROXY=http://127.0.0.1:7890
 	export NO_PROXY=127.0.0.1,localhost
	echo -e "\033[32m[√] Proxy On\033[0m"
}

proxy_off(){
  unset http_proxy
  unset https_proxy
  unset no_proxy
  unset HTTP_PROXY
  unset HTTPS_PROXY
  unset NO_PROXY
  echo -e "\033[31m[×] Proxy Off\033[0m"
}

function prev() {
  PREV=$(fc -lrn | head -n 1)
  sh -c "pet new `printf %q "$PREV"`"
}

# openclaw Control UI 需要 secure context（HTTPS 或 localhost）
# 通过 SSH tunnel 将远程 18789 端口转发到本地，使浏览器以 localhost 访问
openclaw_tunnel() {
  local host="${1:-clawbot@10.1.1.1}"
  local remote_port="${2:-18789}"
  local local_port="${3:-18789}"

  # 检查是否已有隧道
  if pgrep -f "ssh.*-L ${local_port}:localhost:${remote_port}.*${host}" > /dev/null 2>&1; then
    echo -e "\033[33m[!] Tunnel already running (localhost:${local_port} → ${host}:${remote_port})\033[0m"
    echo "    访问: http://localhost:${local_port}"
    echo "    关闭: openclaw_tunnel_stop"
    return 0
  fi

  ssh -fN -L "${local_port}:localhost:${remote_port}" "${host}" && \
    echo -e "\033[32m[√] Tunnel established (localhost:${local_port} → ${host}:${remote_port})\033[0m" && \
    echo "    访问: http://localhost:${local_port}" || \
    echo -e "\033[31m[×] Tunnel failed\033[0m"
}

openclaw_tunnel_stop() {
  local host="${1:-clawbot@10.1.1.1}"
  local pids=$(pgrep -f "ssh.*-L.*localhost.*${host}" 2>/dev/null)
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill
    echo -e "\033[31m[×] Tunnel stopped\033[0m"
  else
    echo -e "\033[33m[!] No active tunnel found\033[0m"
  fi
}
