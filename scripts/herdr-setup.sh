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
  # No tagged releases yet - pinned to the commit installed here.
  "NathanFlurry/herdr-plugin-jj-workspace --ref a9f1d3bcdaa2354e336a5173da85cbe4970c0f2e"
  "aarsh21/herdr-tab-title --ref v0.1.6"
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

# herdr-tab-title ships a prebuilt glibc binary that NixOS can't exec
# (no FHS dynamic linker - see https://nix.dev/permalink/stub-ld). Rebuild
# it in place from the source herdr plugin install already cloned.
tab_title_dir=$(herdr plugin list --json | jq -r '.result.plugins[] | select(.plugin_id=="aarsh21.tab-title") | .plugin_root')
if [[ -n "$tab_title_dir" ]]; then
  (cd "$tab_title_dir" && cargo build --release)
  cp "$tab_title_dir/target/release/herdr-tab-title" "$tab_title_dir/bin/herdr-tab-title"
  herdr plugin action invoke start --plugin aarsh21.tab-title
fi
