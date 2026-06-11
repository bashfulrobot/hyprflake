#!/usr/bin/env bash
# modules/desktop/dank/capture/dank-capture.sh
# Capture the full live settings.json into the consumer repo. The stylix-managed
# theme keys are stripped so the committed profile stays declarative (theme keeps
# tracking Nix) and portable across hosts (no baked-in /nix/store theme paths).
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
marker="$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"
repo="@repoPath@"
stylixKeys="@stylixKeysFile@"

[ -e "$target" ] || {
  echo "No settings.json at $target. Rebuild in capture mode first." >&2
  exit 1
}

mkdir -p "$(dirname "$repo")"
dank-settings-tool without "$target" "$stylixKeys" >"$repo.tmp"
mv "$repo.tmp" "$repo"
# Bless the current live state as captured so the next rebuild re-seeds cleanly
# (the seed re-derives this exact file from defaults + this profile).
dank-settings-tool hash "$target" >"$marker"

echo "Captured DMS settings -> $repo"
echo "Next: commit $repo and run your rebuild."
