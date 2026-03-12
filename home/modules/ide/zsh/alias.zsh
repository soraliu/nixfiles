# -------------------------------------------------------------------------------------------------------------------------------
# alias
# -------------------------------------------------------------------------------------------------------------------------------
alias s='sgpt'
alias sc='sgpt --repl temp --no-cache'
alias ss='sgpt --repl temp --no-cache --describe-shell'

alias z='zellij'
alias zx='zellij action close-tab'
alias zxp='z action go-to-previous-tab && zellij action close-tab'
alias zko='z list-sessions | grep -v EXI | grep -v current | awk "{print \$1}" | sed "s/\x1B\[[0-9;]*[JKmsu]//g" | xargs -I {} bash -c "zellij kill-session {}"'
alias zl='zellij-layout-coding'
alias zlx='zl; zxp'

alias cp='rsync --archive --human-readable --partial --info=progress2'
alias rm='rm -f'
alias mv='mv -f'
# alias f='fasd -f'             # file
# alias d='fasd -d'             # directory
# alias a='fasd -a'             # any

# alias sd='fasd -sid'          # select directory
# alias sf='fasd -sif'          # select file
# alias z='fasd_cd -d'          # jump to directory
# alias zz='fasd_cd -d -i'      # select and jump to directory

# # ssh
# alias ssh-ide='ssh root@ide.soraliu.dev'

# alias cman='man -M /usr/share/man/zh_CN'

# # kubernetes
# alias kx='kubectl ctx'

# # tmux
# alias tl='tmux-layout'
# alias tla='tmux-layout-android'
# alias tw='tmux-window'
# alias tq='tmux kill-window'

# # lynx
# alias lynx='lynx -vikeys'
# alias html='lynx -stdin'

# # display
# alias cat='lolcat'
# alias cats='highlight -O ansi -f'
# alias markdown='highlight -O ansi -f --syntax markdown'

# # xclip
# alias xp='xclip -o -sel c'
# alias xc='xclip -sel c'

# # rg
# alias rgf="rg --files --hidden --glob '!.git'"
