setopt nomonitor nonotify

export LC_ALL=en_US.UTF-8
export TERM="xterm-256color"

# age
export SOPS_AGE_KEY_FILE="$HOME/.age/keys.txt"

# env
# export DISPLAY=${DISPLAY:-:8}

# go
# export GOPATH="$HOME/go"
# export PATH=$PATH:$GOPATH/bin
# export KO_DOCKER_REPO=docker.io/lovesora
# export GOPROXY=https://goproxy.cn
# export GOPRIVATE=github.com/trustwallet/*

# android
# export ANDROID_HOME="$HOME/Android"
# export ANDROID_NDK_HOME="$HOME/Android/android-ndk-r21"
# export PATH="$PATH:$ANDROID_HOME/android-ndk-r21:$ANDROID_HOME/android-ndk-r21:$ANDROID_HOME/tools/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# deno
# export DENO_INSTALL="$HOME/.deno"
# export PATH="$DENO_INSTALL/bin:$PATH"

# python
# export PATH="$PATH:$HOME/.pyenv/shims"

# kubectl
# export KUBECONFIG=$HOME/.kube/config

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# History
setopt HIST_IGNORE_DUPS
HIST_STAMPS="yyyy-mm-dd"

# fix iterm2 zsh-autosuggestion not working
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

# Theme
# ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
