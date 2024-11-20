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
