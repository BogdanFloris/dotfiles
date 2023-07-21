DOTFILES=${HOME}/.dotfiles

all: brew bat

install:
	git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
	stow --restow --ignore ".DS_Store" --target="$(HOME)" --dir="$(DOTFILES)" files

brew:
	brew bundle --file="$(DOTFILES)/Brewfile"

bat:
	bat cache --build

.PHONY: install brew
