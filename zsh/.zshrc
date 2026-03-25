# ~/.zshrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

setopt histignorealldups sharehistory
setopt HIST_IGNORE_SPACE

HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

# Modern job control
setopt check_jobs
setopt check_running_jobs

autoload -Uz compinit
compinit

# Load dircolors for colored completion lists
eval "$(dircolors -b)"

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# Matcher list: allows case insensitivity and partial matching (e.g., f_b -> foo_bar)
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
# Better 'kill' command completion (shows process names/CPU)
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

export EDITOR="nvim"

# Zsh handles path uniqueness automatically with this:
typeset -U path
path+=("$HOME/.local/bin")
path+=("$HOME/go/bin")

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Aliases
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias ll='ls -alF'
alias grep='grep --color=auto'
alias ..='cd ..'

# Git Aliases
alias lg='lazygit'
alias gst='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gp='git push'
alias glp='git pull'
alias ga='git add'
alias gaa='git add --all'
alias gco='git checkout'
alias gb='git branch'
alias gcm='git commit -m'

# FZF
if (( $+commands[bat] )); then
  _preview_bin="bat --style=numbers --color=always --line-range :500 {}"
elif (( $+commands[batcat] )); then
  _preview_bin="batcat --style=numbers --color=always --line-range :500 {}"
else
  _preview_bin="cat {}"
fi
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --preview '$_preview_bin'
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-u:preview-page-up'
  --bind 'ctrl-d:preview-page-down'
"
source <(fzf --zsh)

# Autosuggestions (Ghost Text)
if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
    # Bind Accept to Ctrl+Space
    bindkey '^ ' autosuggest-accept
fi

if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
