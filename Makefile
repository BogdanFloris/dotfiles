DOTFILES=${HOME}/.dotfiles

all: brew bat

install:
	stow --restow --ignore ".DS_Store" --ignore ".stylua.toml" --target="$(HOME)" --dir="$(DOTFILES)" files

brew:
	brew bundle --file="$(DOTFILES)/Brewfile"

bat:
	bat cache --build

.PHONY: install brew
