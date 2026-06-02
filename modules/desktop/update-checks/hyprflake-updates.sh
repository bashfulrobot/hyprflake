#!/usr/bin/env bash
# hyprflake-updates - flag when a newer DankMaterialShell, Hyprland,
# dms-emoji-launcher, or Voxtype is available than what this flake currently
# builds, and surface it on the workstation that consumes the flake.
#
# The @@...@@ tokens are substituted at Nix build time from the flake inputs
# (modules/desktop/update-checks/default.nix). The check polls GitHub's public
# release API (no auth); network failures are non-fatal and leave the cached
# status file untouched. Pull-side analog in the flake repo: `just dms-check`.
#
# Modes:
#   (none)     human-readable report on stdout
#   --notify   send a desktop notification only when something is actionable
#   --oneline  print a single terse line only when something is actionable
set -euo pipefail

CUR_DMS_VERSION="@@DMS_VERSION@@"
CUR_DMS_REV="@@DMS_REV@@"
CUR_HYPR_VERSION="@@HYPR_VERSION@@"
CUR_EMOJI_REV="@@EMOJI_REV@@"
CUR_VOXTYPE_VERSION="@@VOXTYPE_VERSION@@"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprflake"
out="$state_dir/updates.txt"
mkdir -p "$state_dir"

mode="${1:-}"

api() {
  curl -fsS --max-time 10 -H "Accept: application/vnd.github+json" "$1" 2>/dev/null || true
}

# ver_gt A B -> success when A is strictly newer than B (version sort).
ver_gt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

msgs=()
online=0

dms_repo="AvengeMedia/DankMaterialShell"
dms_latest="$(api "https://api.github.com/repos/$dms_repo/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null || true)"
if [ -n "$dms_latest" ]; then
  online=1
  # Does the latest release carry the Lua-config dispatch fix (hl.dsp.* in
  # HyprlandService.qml)? We run a master pin solely for that fix, so this is
  # the signal that a tagged release can finally replace the pin.
  qml="$(api "https://api.github.com/repos/$dms_repo/contents/quickshell/Services/HyprlandService.qml?ref=$dms_latest" | jq -r '.content // empty' 2>/dev/null | base64 -d 2>/dev/null || true)"
  if printf '%s' "$qml" | grep -q 'hl.dsp.focus'; then
    msgs+=("DMS $dms_latest carries the Lua-dispatch fix; drop the hyprflake master pin and track $dms_latest (docs/workarounds.md).")
  fi
  cur_dms="${CUR_DMS_VERSION%%+*}"
  lat_dms="${dms_latest#v}"
  if ver_gt "$lat_dms" "$cur_dms"; then
    msgs+=("DMS release $dms_latest available (currently building $cur_dms @ ${CUR_DMS_REV:0:7}).")
  fi
fi

hypr_latest="$(api "https://api.github.com/repos/hyprwm/Hyprland/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null || true)"
if [ -n "$hypr_latest" ]; then
  online=1
  lat_hypr="${hypr_latest#v}"
  if ver_gt "$lat_hypr" "$CUR_HYPR_VERSION"; then
    msgs+=("Hyprland $lat_hypr released upstream (running $CUR_HYPR_VERSION via nixpkgs; bump nixpkgs once it lands).")
  fi
fi

# dms-emoji-launcher is pinned to a frozen commit on its default branch (it has
# no release tags). Compare against the current default-branch HEAD; any
# difference means the pin can move forward. `commits/HEAD` follows whatever the
# repo's default branch is, so the branch name isn't hardcoded.
emoji_repo="devnullvoid/dms-emoji-launcher"
emoji_head="$(api "https://api.github.com/repos/$emoji_repo/commits/HEAD" | jq -r '.sha // empty' 2>/dev/null || true)"
if [ -n "$emoji_head" ]; then
  online=1
  if [ "$emoji_head" != "$CUR_EMOJI_REV" ]; then
    msgs+=("dms-emoji-launcher has a newer commit ${emoji_head:0:7} (pinned at ${CUR_EMOJI_REV:0:7}); bump the flake input in flake.nix.")
  fi
fi

# voxtype ships release tags; flag when a newer one is out than the built rev.
vox_latest="$(api "https://api.github.com/repos/peteonrails/voxtype/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null || true)"
if [ -n "$vox_latest" ]; then
  online=1
  lat_vox="${vox_latest#v}"
  cur_vox="${CUR_VOXTYPE_VERSION#v}"
  if ver_gt "$lat_vox" "$cur_vox"; then
    msgs+=("Voxtype $vox_latest released (running $cur_vox; bump the voxtype flake input).")
  fi
fi

if [ "$online" -eq 0 ]; then
  # Could not reach GitHub; keep the last known status untouched.
  case "$mode" in
    --notify | --oneline) : ;;
    *) echo "hyprflake: update check skipped (offline)." ;;
  esac
  exit 0
fi

if [ "${#msgs[@]}" -gt 0 ]; then
  printf '%s\n' "${msgs[@]}" >"$out"
  case "$mode" in
    --notify)
      notify-send -a hyprflake -i system-software-update -u normal \
        "hyprflake: updates available" "$(printf '%s\n' "${msgs[@]}")" || true
      ;;
    --oneline)
      echo "hyprflake: ${#msgs[@]} update(s) available - run hyprflake-updates"
      ;;
    *)
      printf '%s\n' "${msgs[@]}"
      ;;
  esac
else
  : >"$out"
  case "$mode" in
    --notify | --oneline) : ;;
    *) echo "hyprflake: DankMaterialShell, Hyprland, dms-emoji-launcher, and Voxtype are up to date." ;;
  esac
fi
