export LANG="en_US.UTF-8"
export PATH=/Users/bogdanfloris/go/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH

# Disable compfix
ZSH_DISABLE_COMPFIX="true"
# Path to your oh-my-zsh installation.
export ZSH="/Users/bogdanfloris/.oh-my-zsh"

HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
plugins=(
  git
  colorize
  colored-man-pages
  extract ssh-agent
  cp
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

export SSH_KEY_PATH="~/.ssh/rsa_id"

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# Keybindings
# zsh-autosuggestions
bindkey '^ ' autosuggest-accept

# Aliases
alias zshconfig="mate ~/.zshrc"
alias ohmyzsh="mate ~/.oh-my-zsh"
alias lg=lazygit
alias ld=lazydocker
alias cat=bat
alias maelstrom="~/maelstrom/maelstrom"
alias chrome-no-sec="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir="/tmp/james_bonds_browser" --disable-web-security"

# NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Poetry
export PATH="$HOME/.poetry/bin:$PATH"

# Zig
export PATH="$HOME/zig:$PATH"

# Yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Rbenv
eval "$(rbenv init - zsh)"

# Environment variables
export DC_USER_ID=10650927
export DC_DCT="eyJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3d3dy5kYXRhY2FtcC5jb20iLCJqdGkiOiIxMDY1MDkyNy04MGE3NTQyMDhiNjc5ZDJhYjcyNjI2NWRkNDEzMTYzOTdjMTVlYzE3OTI3ZjljNDI1MzdiZTY0NTg4ZGIiLCJ1c2VyX2lkIjoxMDY1MDkyNywiZXhwIjoxNzAwMTIzMjkwfQ.lK7PUv2ax3LCSbEZW_-SJ4XpfSJmAKk5SDeajHa6xj6maw27L6EEpC7oi4qh26Xai09bPjohKtzvPynh7RbAL87hd9AgE6WAF3_RHDswOGAahTQXrJUjCV7CL-K9gSF2m7DrV4pgH-39hjlA5aui-SepbTYJzNws_fQihaJYUxzw4suYj5GlRcmuoFqnQmQ34jsHRU2QtVLFXp1GNJmxX_x-fff99pfWIsHEXyFB_Q2KrHcU6-MvLSIWD0mVfSn78hk4ktPno4pJTys2Zt46yjjWFPiXKFPoYcbex-SrZawfWGi1HfZoz94uHhVBna2qEMY7bTMMwsisyL9VONUdFQ"

# pnpm
export PNPM_HOME="/Users/bogdanfloris/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Initialize Starship
eval "$(starship init zsh)"
