# -------------------------------------------------------------------------------------------------------------------------------
# Initial config
# -------------------------------------------------------------------------------------------------------------------------------
# set nonotify
setopt nomonitor nonotify

# set lang & color & user
export LC_ALL=en_US.UTF-8
export TERM="xterm-256color"
export USER=${USER:-$USERNAME}

# fix iterm2 zsh-autosuggestion not working
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

# keys
[ -f $HOME/.keys.zsh ] && source $HOME/.keys.zsh

# set path
export PATH=$HOME/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH
# use commands that installed by mint, like `xcodegen`
[ -d $HOME/.mint/bin ] && export PATH=$HOME/.mint/bin:$PATH

# install sdkman: curl -s "https://get.sdkman.io" | bash
#   sdk install java 17.0.11-zulu
#   sdk use java 17.0.11-zulu
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
[ -e "$SDKMAN_DIR/candidates/java/current/bin" ] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current" && export PATH=$JAVA_HOME/bin:$PATH
