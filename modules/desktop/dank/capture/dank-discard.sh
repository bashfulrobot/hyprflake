#!/usr/bin/env bash
# modules/desktop/dank/capture/dank-discard.sh
# Drop un-captured GUI edits: reset settings.json to the Nix-rendered config.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
marker="$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"

mkdir -p "$cfg" "$(dirname "$marker")"

# Nothing to do if the live file already matches the Nix-rendered config.
if [ -e "$target" ] && dank-settings-tool equal "$target" "@effectiveFile@"; then
  echo "No un-captured changes to discard; settings.json already matches the Nix-rendered config."
  exit 0
fi

install -m644 "@effectiveFile@" "$target"
dank-settings-tool hash "$target" >"$marker"
echo "Discarded un-captured GUI edits; settings.json reset to the Nix-rendered config."
