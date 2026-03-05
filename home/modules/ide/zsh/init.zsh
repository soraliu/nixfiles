# -------------------------------------------------------------------------------------------------------------------------------
# Initial config
# -------------------------------------------------------------------------------------------------------------------------------
# set nonotify
setopt nomonitor nonotify

# set lang & color & user
export LC_ALL=en_US.UTF-8
export LESSCHARSET=utf-8
export TERM="xterm-256color"
export USER=${USER:-$USERNAME}

# fix iterm2 zsh-autosuggestion not working
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

# keys
[ -f $HOME/.keys.zsh ] && source $HOME/.keys.zsh

# set path (Single Source of Truth)
# prepend 语义: 最后执行的优先级最高, 所以按优先级从低到高排列
[ -d "$HOME/.mint/bin" ] && PATH="$HOME/.mint/bin:$PATH"  # macOS mint
[ "$(uname)" = "Darwin" ] && PATH="/opt/homebrew/bin:$PATH" # macOS homebrew
PATH="/nix/var/nix/profiles/default/bin:$PATH"            # nix default profile
PATH="/run/current-system/sw/bin:$PATH"                   # nixos system
PATH="$HOME_PROFILE_DIRECTORY/bin:$PATH"                  # nix home-manager profile
PATH="$GOPATH/bin:$PATH"                                  # golang
PATH="$HOME/.local/bin:$PATH"                             # 用户本地二进制
PATH="${VOLTA_HOME:-$HOME/.volta}/bin:$PATH"              # nodejs (volta) — 最高优先级
export PATH

# install sdkman: curl -s "https://get.sdkman.io" | bash
#   sdk install java 17.0.11-zulu
#   sdk use java 17.0.11-zulu
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
[ -e "$SDKMAN_DIR/candidates/java/current/bin" ] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current" && export PATH=$JAVA_HOME/bin:$PATH
