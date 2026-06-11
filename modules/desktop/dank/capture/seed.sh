#!/usr/bin/env bash
# modules/desktop/dank/capture/seed.sh
# usage: seed.sh <effective.json> <base.json> <target> <baseRef> <marker>
# Seeds a writable settings.json from the Nix-rendered effective config, keeps a
# read-only base reference for the capture diff, and refuses to overwrite live
# edits the user has not captured yet (clobber-guard via canonical-hash marker).
set -euo pipefail

effective="$1"; base="$2"; target="$3"; ref="$4"; marker="$5"

mkdir -p "$(dirname "$target")" "$(dirname "$ref")" "$(dirname "$marker")"

# Refresh the read-only base reference (force-replace; it is mode 444).
rm -f "$ref"
install -m444 "$base" "$ref"

if [ ! -e "$target" ]; then
  install -m644 "$effective" "$target"
  dank-settings-tool hash "$target" > "$marker"
  exit 0
fi

live_hash="$(dank-settings-tool hash "$target")"
seed_hash="$(cat "$marker" 2>/dev/null || true)"

if [ "$live_hash" = "$seed_hash" ]; then
  install -m644 "$effective" "$target"
  dank-settings-tool hash "$target" > "$marker"
else
  echo "hyprflake(dank): settings.json has un-captured GUI edits; not overwriting. Run 'dank-capture' to save them into your repo, or 'dank-discard' to drop them." >&2
  exit 0
fi
