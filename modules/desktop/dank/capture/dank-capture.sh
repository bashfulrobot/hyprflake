#!/usr/bin/env bash
# modules/desktop/dank/capture/dank-capture.sh
# Capture live GUI edits into the consumer repo as a minimal delta.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
ref="$cfg/.dank-defaults.json"
marker="$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"
repo="@repoPath@"

[ -e "$ref" ] || {
  echo "No base reference at $ref. Rebuild in capture mode first." >&2
  exit 1
}
[ -e "$target" ] || {
  echo "No settings.json at $target." >&2
  exit 1
}

# Compute the delta once and reuse it for both the write and the summary, so a
# transient failure in the display step can never appear to fail an already
# committed capture.
delta="$(dank-settings-tool diff "$ref" "$target")"

mkdir -p "$(dirname "$repo")"
printf '%s\n' "$delta" >"$repo.tmp"
mv "$repo.tmp" "$repo"
# Bless current live state as captured so the next rebuild re-seeds cleanly.
dank-settings-tool hash "$target" >"$marker"

echo "Captured DMS overrides -> $repo"
echo "Changed top-level keys:"
printf '%s\n' "$delta" |
  python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join("  "+k for k in sorted(d)) or "  (none)")'
echo "Next: commit $repo and run your rebuild."
