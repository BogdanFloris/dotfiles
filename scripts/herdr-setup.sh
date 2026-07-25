#!/usr/bin/env bash
# Installs herdr plugins and agent integrations that config.toml alone can't
# express (herdr has no declarative plugin manifest - see herdr plugin --help).
# Re-running is safe; `herdr plugin install` no-ops if the ref is already installed.
#
# Run after `stow herdr` (or whenever this list changes):
#   ~/dotfiles/scripts/herdr-setup.sh
set -euo pipefail

plugins=(
  "thanhdat77/herdr-navigator --ref v0.3.3"
  "paulbkim-dev/vim-herdr-navigation --ref v0.1.0"
)

integrations=(
  claude
  codex
)

for spec in "${plugins[@]}"; do
  # shellcheck disable=SC2086
  herdr plugin install $spec --yes
done

for name in "${integrations[@]}"; do
  herdr integration install "$name"
done
