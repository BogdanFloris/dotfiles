#!/usr/bin/env bash
# Builds the Gruvbox-themed glow fork (BogdanFloris/glow) into ~/.local/bin/glow.
set -euo pipefail

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

git clone --depth 1 https://github.com/BogdanFloris/glow.git "$workdir/glow"

mkdir -p "$HOME/.local/bin"
(
  cd "$workdir/glow"
  go build -ldflags="-s -w -X main.Version=3.0.0-gruvbox" -o "$HOME/.local/bin/glow" .
)
