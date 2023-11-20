# Bogdan's Dotfiles

macOS environment managed using git and stow.

## Overview

These dotfiles contain configurations for the following things:

- Homebrew packages and casks
- Neovim custom config
- Kitty terminal config
- Zshrc profile
- Window managemenet config using yabai and skhd

## Install

### Homebrew

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Clone

```
git clone git@github.com:BogdanFloris/dotfiles.git ~/.dotfiles
```

### Make

```
cd ~/.dotfiles
make all
make install
```
