# -------------------------------------------------------------------------------------------------------------------------------
# Install Zinit
#   Zinit ice spec: https://github.com/zdharma-continuum/zinit?tab=readme-ov-file#ice-modifiers
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
zinit lucid atload'source ~/.p10k.zsh; _p9k_precmd' nocd for romkatv/powerlevel10k

# vi mode
#   Github: https://github.com/jeffreytse/zsh-vi-mode
zinit lucid depth"1" for jeffreytse/zsh-vi-mode

# syntax
#   Github: https://github.com/zsh-users/zsh-syntax-highlighting
zinit lucid wait for zsh-users/zsh-syntax-highlighting

# OhMyZsh Plugins
#   Github: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
# OMZ plugins - workspace
zinit lucid wait for OMZP::autojump OMZP::sudo
# OMZ plugins - file
zinit lucid wait for OMZP::extract OMZP::cp
# OMZ plugins - display
zinit lucid wait for OMZP::jsontools OMZP::colored-man-pages
# OMZ plugins - completion
zinit lucid wait for OMZP::docker-compose OMZP::kubectl https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker
# OMZ - alias, don't lazy load to make sure the correct loading of `./alias.zsh`
zinit snippet OMZL::directories.zsh
zinit snippet OMZP::common-aliases
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::git-extras

# autosuggestions
#   Github: https://github.com/zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
zinit lucid wait atload"!_zsh_autosuggest_start" for zsh-users/zsh-autosuggestions
