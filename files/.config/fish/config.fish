/opt/homebrew/bin/brew shellenv | source

set -x LANG "en_US.UTF-8"
set -x SSH_KEY_PATH "~/.ssh/rsa_id"

fish_add_path $HOME/go/bin
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/opt/openjdk/bin
fish_add_path /opt/homebrew/opt/mysql/bin
fish_add_path $HOME/.poetry/bin
fish_add_path $HOME/.zvm/self
fish_add_path $HOME/.zvm/bin
fish_add_path $HOME/.yarn/bin
fish_add_path $HOME/.config/yarn/global/node_modules/.bin
fish_add_path /opt/homebrew/opt/postgresql@16/bin
fish_add_path $HOME/.local/bin

alias lg='lazygit'
alias ld='lazydocker'
alias cat='bat'
alias maelstrom='~/maelstrom/maelstrom'
alias chrome-no-sec='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir="/tmp/james_bonds_browser" --disable-web-security'
alias cd='z'

# Load environment variables from .env file if it exists
if test -f ~/.config/fish/conf.d/env.fish
    source ~/.config/fish/conf.d/env.fish
end

set -x PNPM_HOME "$HOME/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    fish_add_path $PNPM_HOME
end
pyenv init - | source
fnm env --use-on-cd | source

starship init fish | source
atuin init fish | source
zoxide init fish | source

function fish_user_key_bindings
    # Use Cmd+Space to accept autosuggestion
    bind -k nul forward-char
end
