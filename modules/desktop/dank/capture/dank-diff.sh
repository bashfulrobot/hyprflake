#!/usr/bin/env bash
# modules/desktop/dank/capture/dank-diff.sh
# Dry-run: show what dank-capture would change in the repo profile, without
# mutating anything. Compares the committed profile against the theme-stripped
# live settings.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
repo="@repoPath@"
stylixKeys="@stylixKeysFile@"

[ -e "$target" ] || {
  echo "No settings.json at $target. Rebuild in capture mode first." >&2
  exit 1
}

stripped="$(mktemp)"
trap 'rm -f "$stripped"' EXIT
dank-settings-tool without "$target" "$stylixKeys" >"$stripped"

# Compare against the committed profile; fall back to the Nix-rendered overrides
# when nothing has been captured yet.
current="$repo"
[ -e "$current" ] || current="@overridesFile@"

dank-settings-tool diff "$current" "$stripped"
