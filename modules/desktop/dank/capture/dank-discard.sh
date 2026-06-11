#!/usr/bin/env bash
# modules/desktop/dank/capture/dank-discard.sh
# Drop un-captured GUI edits: reset settings.json to the seeded state, i.e.
# merge(hyprflake+stylix defaults, captured profile).
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
marker="$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"
mergedBase="@mergedBaseFile@"
overrides="@overridesFile@"

mkdir -p "$cfg" "$(dirname "$marker")"

desired="$(mktemp)"
trap 'rm -f "$desired"' EXIT
dank-settings-tool merge "$mergedBase" "$overrides" >"$desired"

if [ -e "$target" ] && dank-settings-tool equal "$target" "$desired"; then
  echo "No un-captured changes to discard; settings.json already matches the seeded config."
  exit 0
fi

install -m644 "$desired" "$target"
dank-settings-tool hash "$target" >"$marker"
echo "Discarded un-captured GUI edits; settings.json reset to declarative defaults + captured profile."
