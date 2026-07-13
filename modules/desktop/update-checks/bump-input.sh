#!/usr/bin/env bash
# bump-input [--skip-branch] <input> [flake_path]
# Advance one flake input to its latest upstream ref.
#   tag/sha-pinned -> rewrite the input's url ref in flake.nix, then re-lock.
#   branch-tracking -> `nix flake lock --update-input` (no edit), unless
#                      --skip-branch, in which case it is left untouched (used
#                      by the no-arg batch path so `just bump` never silently
#                      moves every branch input).
# Resolver is `resolve-latest` on PATH (override with $RESOLVE_LATEST); the lock
# command is `nix` (override with $NIX). Prints what it did; makes no commit.
set -euo pipefail

skip_branch=0
if [ "${1:-}" = "--skip-branch" ]; then skip_branch=1; shift; fi

input="${1:?usage: bump-input [--skip-branch] <input> [flake_path]}"
flake="${2:-flake.nix}"
resolve="${RESOLVE_LATEST:-resolve-latest}"
nix="${NIX:-nix}"

# First `url = "..."` line inside the `<input> = {` block (or an inline
# `<input>.url = "..."`). Matches the attr name at the start of a line.
url_line="$(awk -v want="$input" '
  $0 ~ "^[[:space:]]*"want"[[:space:]]*=[[:space:]]*\\{" { inblk=1 }
  $0 ~ "^[[:space:]]*"want"\\.url[[:space:]]*=" { print; exit }
  inblk && /url[[:space:]]*=[[:space:]]*"/ { print; exit }
' "$flake")"
[ -n "$url_line" ] || { echo "bump-input: input '$input' not found in $flake" >&2; exit 1; }

url="${url_line#*\"}"; url="${url%%\"*}"        # github:owner/repo[/ref]
path="${url#github:}"                            # owner/repo[/ref]
repo="$(printf '%s' "$path" | cut -d/ -f1,2)"    # owner/repo
ref="$(printf '%s' "$path" | cut -d/ -f3-)"      # ref or empty

mode=branch
if [ -n "$ref" ]; then
  if printf '%s' "$ref" | grep -qE '^v?[0-9]+\.[0-9]+'; then mode=tag
  elif printf '%s' "$ref" | grep -qiE '^[0-9a-f]{7,40}$'; then mode=sha
  fi
fi

if [ "$mode" = branch ]; then
  if [ "$skip_branch" -eq 1 ]; then
    echo "bump-input: $input tracks a branch; skipped"
    exit 0
  fi
  echo "bump-input: $input tracks a branch; re-locking via update-input"
  "$nix" flake lock --update-input "$input"
  exit 0
fi

new="$("$resolve" "$repo" "$mode")" || { echo "bump-input: resolver failed for $repo" >&2; exit 1; }
[ -n "$new" ] || { echo "bump-input: empty latest $mode for $repo" >&2; exit 1; }

if [ "$new" = "$ref" ]; then
  echo "bump-input: $input already at $ref"
  exit 0
fi

# Rewrite only this input's url ref. '|' delimiter avoids clashing with '/'.
sed -i "s|github:$repo/$ref|github:$repo/$new|" "$flake"
echo "bump-input: $input $ref -> $new"
"$nix" flake lock --update-input "$input"
