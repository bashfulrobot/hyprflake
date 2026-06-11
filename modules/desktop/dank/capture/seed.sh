#!/usr/bin/env bash
# modules/desktop/dank/capture/seed.sh
# usage: seed.sh <mergedBase.json> <overrides.json> <target> <marker>
# Seeds a writable, complete settings.json = merge(hyprflake+stylix defaults,
# captured overrides). Writing the *full* file (not a minimal subset) means DMS
# finds every key already present and does not re-materialise its defaults on
# launch, so the live file stays stable. Refuses to overwrite GUI edits the user
# has not captured yet (clobber-guard via canonical-hash marker).
set -euo pipefail

mergedBase="$1"
overrides="$2"
target="$3"
marker="$4"

mkdir -p "$(dirname "$target")" "$(dirname "$marker")"

desired="$(mktemp)"
trap 'rm -f "$desired"' EXIT
# Captured GUI settings win over the declarative defaults; the stylix theme keys
# live only in mergedBase (dank-capture strips them from the repo), so the theme
# always tracks Nix.
dank-settings-tool merge "$mergedBase" "$overrides" >"$desired"

if [ ! -e "$target" ]; then
  install -m644 "$desired" "$target"
  dank-settings-tool hash "$target" >"$marker"
  exit 0
fi

live_hash="$(dank-settings-tool hash "$target")"
seed_hash="$(cat "$marker" 2>/dev/null || true)"

if [ "$live_hash" = "$seed_hash" ]; then
  # No un-captured edits. Re-apply the desired state so changes to the defaults
  # or the captured profile (e.g. another host in the group) propagate, but skip
  # the write when nothing changed to avoid a needless DMS reload.
  if ! dank-settings-tool equal "$target" "$desired"; then
    install -m644 "$desired" "$target"
    dank-settings-tool hash "$target" >"$marker"
  fi
else
  echo "hyprflake(dank): settings.json has un-captured GUI edits; not overwriting. Run 'dank-capture' to save them into your repo, or 'dank-discard' to drop them." >&2
  exit 0
fi
