# -------------------------------------------------------------------------------------------------------------------------------
# Install Zinit
# -------------------------------------------------------------------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# -------------------------------------------------------------------------------------------------------------------------------
# Install plugins by zinit
# -------------------------------------------------------------------------------------------------------------------------------
# Theme
#   Github: https://github.com/romkatv/powerlevel10k/tree/master
zinit ice wait'!' lucid atload'source ~/.p10k.zsh; _p9k_precmd' nocd
zinit light romkatv/powerlevel10k

# autosuggestions
#   Github: https://github.com/zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
zinit ice wait lucid atload"!_zsh_autosuggest_start"
zinit load zsh-users/zsh-autosuggestions

# syntax
#   Github: https://github.com/zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-syntax-highlighting

# vi mode
#   Github: https://github.com/jeffreytse/zsh-vi-mode
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode


# OMZ plugins - workspace
zinit wait lucid for OMZP::autojump
zinit wait lucid for OMZP::sudo
# OMZ plugins - file
zinit wait lucid for OMZP::extract
zinit wait lucid for OMZP::cp
# OMZ plugins - display
zinit wait lucid for OMZP::jsontools
zinit wait lucid for OMZP::colored-man-pages
# OMZ plugins - alias
zinit wait lucid for OMZP::common-aliases
zinit wait lucid for OMZP::git
# OMZ plugins - completion
zinit wait lucid for OMZP::docker
zinit wait lucid for OMZP::docker-compose
zinit wait lucid for OMZP::kubectl
