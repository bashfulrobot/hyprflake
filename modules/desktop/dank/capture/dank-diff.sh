#!/usr/bin/env bash
# modules/desktop/dank/capture/dank-diff.sh
# Dry-run: show the delta dank-capture would write, without mutating anything.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
ref="$cfg/.dank-defaults.json"

[ -e "$ref" ] && [ -e "$target" ] || {
  echo "Rebuild in capture mode first." >&2
  exit 1
}
dank-settings-tool diff "$ref" "$target"
