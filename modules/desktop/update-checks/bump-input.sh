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
#
# The url line is located by NUMBER, scoped strictly to the target input's own
# brace-balanced block and skipping comment lines, so:
#   - an input with no url of its own (a follows-only block) errors instead of
#     silently grabbing a later input's url;
#   - a commented-out `# url = ...` never shadows the live one;
#   - the rewrite touches only that one line, as a literal string swap, so a
#     duplicate `github:owner/repo/ref` elsewhere in the file is left alone and
#     regex metacharacters in $repo/$ref (dots in v1.5.0, apple-fonts.nix) can't
#     act as wildcards.
# NOTE: mode detection is heuristic — a dotless year-style tag (e.g. "2024") or
# a hex-named branch would be misclassified. Not handled here; refs in this repo
# are dotted tags or 7-40 char shas.
set -euo pipefail

skip_branch=0
if [ "${1:-}" = "--skip-branch" ]; then skip_branch=1; shift; fi

input="${1:?usage: bump-input [--skip-branch] <input> [flake_path]}"
flake="${2:-flake.nix}"
resolve="${RESOLVE_LATEST:-resolve-latest}"
nix="${NIX:-nix}"

[ -f "$flake" ] || { echo "bump-input: flake file '$flake' not found" >&2; exit 1; }

# Line NUMBER of the url that belongs to <input>:
#   - inline form `<input>.url = "..."` (comment lines excluded), or
#   - the first `url = "..."` inside the `<input> = { ... }` block, tracking
#     brace depth so the search stops at the block's own closing brace (a block
#     with no url of its own prints nothing) and skipping comment lines.
lineno="$(awk -v want="$input" '
  $0 !~ /^[[:space:]]*#/ && $0 ~ "^[[:space:]]*"want"\\.url[[:space:]]*=" { print NR; exit }
  !inblk && $0 ~ "^[[:space:]]*"want"[[:space:]]*=[[:space:]]*\\{" { inblk=1; depth=0 }
  inblk {
    if ($0 ~ /^[[:space:]]*#/) next
    if ($0 ~ /url[[:space:]]*=[[:space:]]*"/) { print NR; exit }
    line=$0
    depth += gsub(/[{]/,"&",line) - gsub(/[}]/,"&",line)
    if (depth <= 0) exit
  }
' "$flake")"
[ -n "$lineno" ] || { echo "bump-input: input '$input' not found in $flake" >&2; exit 1; }

url_line="$(sed -n "${lineno}p" "$flake")"
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

# Rewrite ONLY the matched line, as a bash literal string swap (no regex, no
# sed replacement metacharacters), then write it back at that line number so no
# other line — even an identical duplicate ref — is touched.
new_line="${url_line/github:$repo\/$ref/github:$repo\/$new}"
tmp="$(mktemp)"
REPL="$new_line" awk -v n="$lineno" 'NR==n { print ENVIRON["REPL"]; next } { print }' \
  "$flake" >"$tmp"
cat "$tmp" >"$flake"          # truncate-in-place: keeps flake.nix's inode + mode
rm -f "$tmp"
echo "bump-input: $input $ref -> $new"
"$nix" flake lock --update-input "$input"
