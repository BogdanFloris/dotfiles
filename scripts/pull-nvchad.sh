#!/bin/bash
# This script pulls the latest version of NvChad from the git repository

if cd ~/.config/nvim;
then
    echo "Pulling NvChad from git repository..."
    git pull
    echo "NvChad has been updated!"
else
    echo "NvChad is not installed!"
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    echo "NvChad has been installed"
fi

