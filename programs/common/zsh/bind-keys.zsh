# -------------------------------------------------------------------------------------------------------------------------------
# bindkey
# -------------------------------------------------------------------------------------------------------------------------------
function zvm_config() {
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
  ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
}

function bindkey_of_sgpt() {
  # Search by Shell-GPT
  _sgpt_zsh() {
  if [[ -n "$BUFFER" ]]; then
      _sgpt_prev_cmd=$BUFFER
      BUFFER+="⌛"
      zle -I && zle redisplay
      BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd")
      zle end-of-line
  fi
  }
  zle -N _sgpt_zsh
  bindkey '^_' _sgpt_zsh
}

function bindkey_of_edit() {
  # undo
  bindkey '^U' undo

  # vi movement
  bindkey -M viins '^J' vi-backward-blank-word
  bindkey -M viins '^K' vi-forward-blank-word
  bindkey -M viins '^B' beginning-of-line

  # edit command line
  bindkey -M vicmd '^V' zvm_vi_edit_command_line

}

function bindkey_of_fzf() {
  fzf-pet-widget() {
    LBUFFER="$(pet search --color)"
    zle reset-prompt
  }
  zle     -N   fzf-pet-widget

  bindkey           '^R' fzf-history-widget
  bindkey -M vicmd  '^R' fzf-history-widget
  bindkey           '^T' fzf-file-widget
  bindkey -M vicmd  '^O' fzf-file-widget
  bindkey           '^]' fzf-cd-widget
  bindkey -M vicmd  '^]' fzf-cd-widget
  bindkey           "^O" fzf-pet-widget
  bindkey -M vicmd  "^O" fzf-pet-widget
}

function zvm_after_init() {
  bindkey_of_sgpt
  bindkey_of_edit
  bindkey_of_fzf
}
