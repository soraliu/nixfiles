# -------------------------------------------------------------------------------------------------------------------------------
# functions
# -------------------------------------------------------------------------------------------------------------------------------
zellij-layout-coding() {
  path_to_cwd=${1:-$(pwd)}
  zellij action new-tab --layout coding --name "$(basename ${path_to_cwd})" --cwd="${path_to_cwd}"
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
