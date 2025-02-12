#!/usr/bin/env fish

# Install fisher if not already installed
if not type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
end

# Install essential plugins
fisher install \
    jorgebucaran/autopair.fish \       # Auto-closing pairs
    PatrickF1/fzf.fish \               # Fuzzy finding
    meaningful-ooo/sponge \            # Pattern matching suggestion
    franciscolourenco/done             # Notification on long-running commands
    danhper/fish-ssh-agent \           # SSH agent integration
    jhillyerd/plugin-git \             # Git abbreviations and utilities
    jethrokuan/z \                     # Directory jumping (like autojump/fasd)
    gazorby/fish-abbreviation-tips \   # Shows abbreviation suggestions as you type
    nickeb96/puffer-fish \             # Adds better expandable aliases
    patrickf1/colored_man_pages.fish \ # Colored man pages
    jomik/fish-gruvbox \               # Gruvbox color scheme for fish
    budimanjojo/tmux.fish              # Tmux settings and aliases
