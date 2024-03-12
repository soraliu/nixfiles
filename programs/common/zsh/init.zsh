# -------------------------------------------------------------------------------------------------------------------------------
# Initial config
# -------------------------------------------------------------------------------------------------------------------------------
setopt nomonitor nonotify

export LC_ALL=en_US.UTF-8
export TERM="xterm-256color"
export USER=${USER:-$USERNAME}

# fix iterm2 zsh-autosuggestion not working
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

# keys
[ -f ~/.keys.zsh ] && source ~/.keys.zsh
