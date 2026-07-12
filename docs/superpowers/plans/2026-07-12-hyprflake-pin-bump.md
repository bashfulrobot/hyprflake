# hyprflake pin-bump workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn "the notifier reminded me, now I hand-edit `flake.nix`" into a single `just bump <input>` that advances a tag/SHA-pinned input to its latest upstream and re-locks, backed by a notifier that only fires actionable messages.

**Architecture:** Two small POSIX-ish bash scripts under `modules/desktop/update-checks/` — `resolve-latest.sh` (repo + mode → latest ref, curl/public-API, shared) and `bump-input.sh` (parse `flake.nix`, rewrite the input's `url` ref, re-lock; branch inputs delegate to `nix flake lock`). A `just bump` recipe wires them pull-side. The existing `hyprflake-updates.sh` notifier is edited to drop its obsolete unconditional DMS advisory, replace it with a "nixpkgs `dms-shell` caught up → drop the override" check, name the exact command in every message, and reuse `resolve-latest` for its fetches. Tests are bats, run as Nix flake checks like the existing `dank-seed-bats`.

**Tech Stack:** bash, curl + jq (GitHub public API), Nix flakes, just, bats.

---

## File Structure

- Create: `modules/desktop/update-checks/resolve-latest.sh` — pure "latest ref for repo+mode" resolver (curl). One responsibility.
- Create: `modules/desktop/update-checks/bump-input.sh` — parse `flake.nix`, rewrite one input's ref, re-lock. Calls `resolve-latest`.
- Create: `modules/desktop/update-checks/tests/resolve-latest.bats` — unit tests, curl stubbed.
- Create: `modules/desktop/update-checks/tests/bump-input.bats` — unit tests, `resolve-latest` + `nix` stubbed, fixture `flake.nix`.
- Create: `modules/desktop/update-checks/tests/fixtures/flake.nix` — minimal fixture with one tag, one sha, one branch input.
- Create: `modules/desktop/update-checks/tests/notifier.bats` — covers the re-scoped DMS message, curl stubbed.
- Modify: `modules/desktop/update-checks/hyprflake-updates.sh` — re-scope DMS advisory, name commands, call `resolve-latest`.
- Modify: `modules/desktop/update-checks/default.nix` — package `resolve-latest` and add to the notifier's `runtimeInputs`; refresh option docs.
- Modify: `justfile` — add `bump` recipe.
- Modify: `flake.nix` — add three `checks.x86_64-linux` entries (mirror `dank-seed-bats`).
- Modify: `docs/workarounds.md` — update the DMS section to reflect the override (not master-pin) framing.

---

## Task 1: `resolve-latest.sh` — latest ref for repo + mode

**Files:**
- Create: `modules/desktop/update-checks/resolve-latest.sh`
- Test: `modules/desktop/update-checks/tests/resolve-latest.bats`
- Modify: `flake.nix` (add check `update-checks-resolve-bats`)

- [ ] **Step 1: Write the failing test**

Create `modules/desktop/update-checks/tests/resolve-latest.bats`:

```bash
# modules/desktop/update-checks/tests/resolve-latest.bats
setup() {
  TMP="$(mktemp -d)"; export TMP
  mkdir -p "$TMP/bin"
  # Stub curl: canned JSON keyed off the request URL (the last argument).
  cat >"$TMP/bin/curl" <<'EOF'
#!/bin/sh
for a in "$@"; do url="$a"; done
case "$url" in
  *"/releases/latest") printf '{"tag_name":"v9.9.9"}'; exit 0 ;;
  *"/commits/HEAD")    printf '{"sha":"abc123def456abc123def456abc123def456abcd"}'; exit 0 ;;
  *) exit 22 ;;
esac
EOF
  chmod +x "$TMP/bin/curl"
  export PATH="$TMP/bin:$PATH"
  SCRIPT="$BATS_TEST_DIRNAME/../resolve-latest.sh"
}
teardown() { rm -rf "$TMP"; }

@test "tag mode prints the latest release tag" {
  run bash "$SCRIPT" owner/repo tag
  [ "$status" -eq 0 ]
  [ "$output" = "v9.9.9" ]
}

@test "sha mode prints the default-branch HEAD sha" {
  run bash "$SCRIPT" owner/repo sha
  [ "$status" -eq 0 ]
  [ "$output" = "abc123def456abc123def456abc123def456abcd" ]
}

@test "unknown mode exits 2" {
  run bash "$SCRIPT" owner/repo branch
  [ "$status" -eq 2 ]
}

@test "network failure exits non-zero with no stdout" {
  # point at a repo whose URL the stub does not match -> curl exits 22
  PATH="$TMP/bin:$PATH" run bash "$SCRIPT" owner/repo tag
  # override stub to always fail
  cat >"$TMP/bin/curl" <<'EOF'
#!/bin/sh
exit 22
EOF
  chmod +x "$TMP/bin/curl"
  run bash "$SCRIPT" owner/repo tag
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd modules/desktop/update-checks && bats tests/resolve-latest.bats`
Expected: FAIL — `resolve-latest.sh` does not exist (bats reports the file/command not found).

- [ ] **Step 3: Write minimal implementation**

Create `modules/desktop/update-checks/resolve-latest.sh`:

```bash
#!/usr/bin/env bash
# resolve-latest <owner/repo> <tag|sha>
# Print the latest upstream ref a hyprflake input should pin:
#   tag -> latest release tag (e.g. v1.6.0) from the GitHub releases API
#   sha -> default-branch HEAD commit SHA (commits/HEAD follows the default
#          branch, so the branch name is never hardcoded)
# Public GitHub API over curl, so it runs both in the flake repo (just bump)
# and on a workstation (the update-checks notifier). No auth. On any network
# or parse failure, print nothing and exit non-zero.
set -euo pipefail

repo="${1:?usage: resolve-latest <owner/repo> <tag|sha>}"
mode="${2:?usage: resolve-latest <owner/repo> <tag|sha>}"

api() {
  curl -fsS --max-time 10 -H "Accept: application/vnd.github+json" "$1"
}

case "$mode" in
  tag) api "https://api.github.com/repos/$repo/releases/latest" | jq -er '.tag_name' ;;
  sha) api "https://api.github.com/repos/$repo/commits/HEAD"     | jq -er '.sha' ;;
  *)   echo "resolve-latest: unknown mode '$mode' (want tag|sha)" >&2; exit 2 ;;
esac
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd modules/desktop/update-checks && bats tests/resolve-latest.bats`
Expected: PASS — 4 tests.

- [ ] **Step 5: Wire the bats file as a Nix flake check**

In `flake.nix`, inside `checks.x86_64-linux = let pkgs = ...; in { ... }` (after the `dank-seed-bats` entry, before the closing `};` at line ~145), add:

```nix
          update-checks-resolve-bats = pkgs.runCommand "update-checks-resolve-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils pkgs.jq ]; } ''
            cp -r ${./modules/desktop/update-checks} uc
            chmod -R u+w uc
            cd uc && bats tests/resolve-latest.bats
            touch $out
          '';
```

- [ ] **Step 6: Run the flake check**

Run: `nix build .#checks.x86_64-linux.update-checks-resolve-bats -L`
Expected: builds successfully (bats passes inside the sandbox; the stub `curl` on `PATH` is used, real `jq` from `nativeBuildInputs`).

- [ ] **Step 7: Commit**

```bash
git add modules/desktop/update-checks/resolve-latest.sh \
        modules/desktop/update-checks/tests/resolve-latest.bats flake.nix
git commit -S -m "feat(update-checks): add resolve-latest ref resolver + tests"
```

---

## Task 2: `bump-input.sh` — rewrite one input's ref and re-lock

**Files:**
- Create: `modules/desktop/update-checks/bump-input.sh`
- Create: `modules/desktop/update-checks/tests/fixtures/flake.nix`
- Test: `modules/desktop/update-checks/tests/bump-input.bats`
- Modify: `flake.nix` (add check `update-checks-bump-bats`)

- [ ] **Step 1: Write the fixture flake**

Create `modules/desktop/update-checks/tests/fixtures/flake.nix` (only the input shapes matter):

```nix
{
  inputs = {
    voxtype.url = "github:peteonrails/voxtype";
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell/v1.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher/8ff394e3ddfcb2fd755ed2e7b4c6f01f3e26e596";
      flake = false;
    };
  };
}
```

- [ ] **Step 2: Write the failing test**

Create `modules/desktop/update-checks/tests/bump-input.bats`:

```bash
# modules/desktop/update-checks/tests/bump-input.bats
setup() {
  TMP="$(mktemp -d)"; export TMP
  cp "$BATS_TEST_DIRNAME/fixtures/flake.nix" "$TMP/flake.nix"
  mkdir -p "$TMP/bin"

  # Stub resolve-latest: tag -> v2.0.0, sha -> forty 'a's.
  cat >"$TMP/bin/resolve-latest" <<'EOF'
#!/bin/sh
case "$2" in
  tag) echo "v2.0.0" ;;
  sha) echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$TMP/bin/resolve-latest"

  # Stub nix: log invocations instead of touching the network.
  cat >"$TMP/bin/nix" <<'EOF'
#!/bin/sh
echo "nix $*" >>"$TMP/nix.log"
EOF
  chmod +x "$TMP/bin/nix"
  export PATH="$TMP/bin:$PATH"

  SCRIPT="$BATS_TEST_DIRNAME/../bump-input.sh"
}
teardown() { rm -rf "$TMP"; }

@test "tag input: url ref rewritten to latest and re-locked" {
  run bash "$SCRIPT" dank-material-shell "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'github:AvengeMedia/DankMaterialShell/v2.0.0' "$TMP/flake.nix"
  ! grep -q '/v1.5.0' "$TMP/flake.nix"
  grep -q 'flake lock --update-input dank-material-shell' "$TMP/nix.log"
}

@test "sha input: url ref rewritten to latest HEAD sha" {
  run bash "$SCRIPT" dms-emoji-launcher "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'dms-emoji-launcher/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' "$TMP/flake.nix"
}

@test "branch input: no url edit, delegates to update-input" {
  run bash "$SCRIPT" voxtype "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'github:peteonrails/voxtype"' "$TMP/flake.nix"   # unchanged
  grep -q 'flake lock --update-input voxtype' "$TMP/nix.log"
}

@test "already-latest tag: no change, no re-lock" {
  # Point the stub at the pinned version so latest == current.
  cat >"$TMP/bin/resolve-latest" <<'EOF'
#!/bin/sh
[ "$2" = tag ] && echo "v1.5.0"
EOF
  chmod +x "$TMP/bin/resolve-latest"
  run bash "$SCRIPT" dank-material-shell "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/nix.log" ]
}

@test "unknown input exits non-zero" {
  run bash "$SCRIPT" nope "$TMP/flake.nix"
  [ "$status" -ne 0 ]
}

@test "--skip-branch: branch input is skipped, not re-locked" {
  run bash "$SCRIPT" --skip-branch voxtype "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/nix.log" ]
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd modules/desktop/update-checks && bats tests/bump-input.bats`
Expected: FAIL — `bump-input.sh` does not exist.

- [ ] **Step 4: Write minimal implementation**

Create `modules/desktop/update-checks/bump-input.sh`:

```bash
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd modules/desktop/update-checks && bats tests/bump-input.bats`
Expected: PASS — 6 tests.

- [ ] **Step 6: Wire the bats file as a Nix flake check**

In `flake.nix` `checks.x86_64-linux`, add after the Task 1 entry:

```nix
          update-checks-bump-bats = pkgs.runCommand "update-checks-bump-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils pkgs.gnugrep pkgs.gawk ]; } ''
            cp -r ${./modules/desktop/update-checks} uc
            chmod -R u+w uc
            cd uc && bats tests/bump-input.bats
            touch $out
          '';
```

- [ ] **Step 7: Run the flake check**

Run: `nix build .#checks.x86_64-linux.update-checks-bump-bats -L`
Expected: builds successfully.

- [ ] **Step 8: Commit**

```bash
git add modules/desktop/update-checks/bump-input.sh \
        modules/desktop/update-checks/tests/bump-input.bats \
        modules/desktop/update-checks/tests/fixtures/flake.nix flake.nix
git commit -S -m "feat(update-checks): add bump-input flake.nix ref rewriter + tests"
```

---

## Task 3: `just bump` recipe

**Files:**
- Modify: `justfile` (add `bump` recipe after `update-input`, ~line 57)

- [ ] **Step 1: Add the recipe**

In `justfile`, after the `update-input` recipe (line 55-56), insert:

```just
# Advance a tag/SHA-pinned input to its latest upstream ref and re-lock, then
# print the diff to review before committing + `just release`. With no argument,
# every tag/SHA-pinned input is bumped (branch inputs are left untouched; use
# `just update` / `just update-input` for those).
bump input="":
    #!/usr/bin/env bash
    set -euo pipefail
    dir=modules/desktop/update-checks
    export RESOLVE_LATEST="$PWD/$dir/resolve-latest.sh"
    if [ -n "{{input}}" ]; then
      bash "$dir/bump-input.sh" "{{input}}"
    else
      # every top-level input block; bump-input skips branch + already-latest.
      grep -oE '^    [a-z0-9-]+ = \{' flake.nix | sed -E 's/^ +//; s/ = \{//' \
        | while read -r name; do
            bash "$dir/bump-input.sh" --skip-branch "$name" || true
          done
    fi
    git --no-pager diff -- flake.nix flake.lock
```

- [ ] **Step 2: Verify the recipe parses and lists**

Run: `just --list | grep -A1 '^ *bump'`
Expected: the `bump` recipe appears with its doc line.

- [ ] **Step 3: Smoke-test a no-op bump (network required)**

Run: `just bump dank-material-shell`
Expected: prints either `already at v1.5.0` (if upstream latest is still v1.5.0) or a `v1.5.0 -> vX.Y.Z` line plus a `flake.nix`/`flake.lock` diff. Either way, exit 0. If a diff appears, discard it for now: `git checkout -- flake.nix flake.lock`.

- [ ] **Step 4: Commit**

```bash
git add justfile
git commit -S -m "feat(justfile): add \`just bump\` for one-command input pin bumps"
```

---

## Task 4: Re-scope the notifier + name commands + reuse resolve-latest

**Files:**
- Modify: `modules/desktop/update-checks/hyprflake-updates.sh`
- Modify: `modules/desktop/update-checks/default.nix`
- Create: `modules/desktop/update-checks/tests/notifier.bats`
- Modify: `flake.nix` (add check `update-checks-notifier-bats`)

- [ ] **Step 1: Write the failing test for the re-scoped DMS message**

Create `modules/desktop/update-checks/tests/notifier.bats`. It substitutes the `@@...@@` tokens (as the Nix build does) into a temp copy, stubs `curl` to return a controllable nixpkgs `dms-shell` version, and runs the script in `--oneline` mode:

```bash
# modules/desktop/update-checks/tests/notifier.bats
setup() {
  TMP="$(mktemp -d)"; export TMP
  export XDG_STATE_HOME="$TMP/state"
  mkdir -p "$TMP/bin"

  # Bake the tokens the Nix build would substitute: pinned DMS 1.5.0.
  sed -e 's/@@DMS_VERSION@@/1.5.0/' \
      -e 's/@@DMS_REV@@/deadbeef/' \
      -e 's/@@HYPR_VERSION@@/0.50.0/' \
      -e 's/@@EMOJI_REV@@/8ff394e/' \
      -e 's/@@VOXTYPE_VERSION@@/0.8.0/' \
      "$BATS_TEST_DIRNAME/../hyprflake-updates.sh" >"$TMP/notifier.sh"

  # NIXPKGS_DMS controls the nixpkgs dms-shell version the curl stub reports.
  cat >"$TMP/bin/curl" <<EOF
#!/bin/sh
for a in "\$@"; do url="\$a"; done
case "\$url" in
  *dms-shell/package.nix*)
    printf '{"content":"%s"}' "\$(printf 'version = \"%s\";' "\${NIXPKGS_DMS:-1.5.0}" | base64 -w0)" ;;
  *DankMaterialShell*releases/latest*) printf '{"tag_name":"v1.5.0"}' ;;
  *HyprlandService.qml*) printf '{"content":""}' ;;
  *hyprland/package.nix*) printf '{"content":"%s"}' "\$(printf 'version = \"0.50.0\";' | base64 -w0)" ;;
  *dms-emoji-launcher*commits/HEAD*) printf '{"sha":"8ff394e"}' ;;
  *voxtype*releases/latest*) printf '{"tag_name":"v0.8.0"}' ;;
  *) printf '{}' ;;
esac
EOF
  chmod +x "$TMP/bin/curl"
  export PATH="$TMP/bin:$PATH"
}
teardown() { rm -rf "$TMP"; }

@test "fires 'drop the override' when nixpkgs dms-shell >= pinned" {
  NIXPKGS_DMS=1.5.0 run bash "$TMP/notifier.sh" --oneline
  [ "$status" -eq 0 ]
  grep -q 'pkgs.dms-shell' "$XDG_STATE_HOME/hyprflake/updates.txt"
}

@test "silent when nixpkgs dms-shell still behind pinned" {
  NIXPKGS_DMS=1.4.6 run bash "$TMP/notifier.sh" --oneline
  [ "$status" -eq 0 ]
  ! grep -q 'pkgs.dms-shell' "$XDG_STATE_HOME/hyprflake/updates.txt" 2>/dev/null || false
}

@test "does not emit the old unconditional 'drop the master pin' text" {
  NIXPKGS_DMS=1.5.0 run bash "$TMP/notifier.sh"
  ! printf '%s' "$output" | grep -q 'drop the hyprflake master pin'
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd modules/desktop/update-checks && bats tests/notifier.bats`
Expected: FAIL — the current script still emits "drop the hyprflake master pin" and never checks nixpkgs `dms-shell`, so tests 1 and 3 fail.

- [ ] **Step 3: Re-scope the DMS block in `hyprflake-updates.sh`**

Replace the DMS advisory block (the `qml=...` fetch and the `if printf '%s' "$qml" | grep -q 'hl.dsp.focus'; then msgs+=("DMS ... drop the hyprflake master pin ...") fi` lines, ~45–51) with a nixpkgs-caught-up check. Keep the version-comparison block (`ver_gt "$lat_dms" "$cur_dms"`) but rename its message to name the command:

```bash
  cur_dms="${CUR_DMS_VERSION%%+*}"
  lat_dms="${dms_latest#v}"
  if ver_gt "$lat_dms" "$cur_dms"; then
    msgs+=("DMS release $dms_latest available (building $cur_dms) - run: just bump dank-material-shell")
  fi
fi

# The dank-material-shell input is pinned ahead of nixpkgs' dms-shell only to
# get a fix nixpkgs had not shipped yet. Once nixpkgs' dms-shell reaches the
# pinned version, the flake-input override (modules/desktop/dank) can be dropped
# in favour of pkgs.dms-shell. Read nixpkgs' version off the channel branch,
# same pattern as the Hyprland check below.
nixpkgs_dms="$(api "https://api.github.com/repos/NixOS/nixpkgs/contents/pkgs/by-name/dm/dms-shell/package.nix?ref=nixos-unstable" | jq -r '.content // empty' 2>/dev/null | base64 -d 2>/dev/null | grep -m1 -E '^[[:space:]]*version = "' 2>/dev/null || true)"
nixpkgs_dms="${nixpkgs_dms#*\"}"; nixpkgs_dms="${nixpkgs_dms%%\"*}"
if [ -n "$nixpkgs_dms" ]; then
  online=1
  pin_dms="${CUR_DMS_VERSION%%+*}"
  # nixpkgs >= pinned  <=>  NOT (pinned > nixpkgs)
  if ! ver_gt "$pin_dms" "$nixpkgs_dms"; then
    msgs+=("nixpkgs dms-shell $nixpkgs_dms >= pinned $pin_dms - drop the dank-material-shell override and restore pkgs.dms-shell (modules/desktop/dank).")
  fi
fi
```

Note: the DMS-release block above is kept but had its message reworded; the new nixpkgs block is added right after the closing `fi` of the `if [ -n "$dms_latest" ]` section.

- [ ] **Step 4: Name the command in the remaining messages**

Reword the Hyprland, emoji, and voxtype messages to name their command:

- Hyprland: `... in nixos-unstable (building $CUR_HYPR_VERSION) - run: just update-input nixpkgs`
- emoji: `dms-emoji-launcher has newer commit ${emoji_head:0:7} - run: just bump dms-emoji-launcher`
- voxtype: `Voxtype $vox_latest released (running $cur_vox) - run: just update-input voxtype`

(voxtype tracks a branch, so its command is `update-input`, not `bump`.)

- [ ] **Step 5: Run test to verify it passes**

Run: `cd modules/desktop/update-checks && bats tests/notifier.bats`
Expected: PASS — 3 tests.

- [ ] **Step 6: Refresh module option docs in `default.nix`**

In `modules/desktop/update-checks/default.nix`, update the header comment (lines 3–13) and the `enable`/module description text to drop the "pinned to a master commit" framing and say the check flags (a) newer releases of pinned inputs — actionable via `just bump` — and (b) when nixpkgs' `dms-shell` catches up so the override can be dropped. No option schema changes.

- [ ] **Step 7: Wire the notifier bats file as a flake check**

In `flake.nix` `checks.x86_64-linux`, add:

```nix
          update-checks-notifier-bats = pkgs.runCommand "update-checks-notifier-bats"
            { nativeBuildInputs = [ pkgs.bats pkgs.coreutils pkgs.gnugrep pkgs.jq ]; } ''
            cp -r ${./modules/desktop/update-checks} uc
            chmod -R u+w uc
            cd uc && bats tests/notifier.bats
            touch $out
          '';
```

- [ ] **Step 8: Run the flake check + full check**

Run: `nix build .#checks.x86_64-linux.update-checks-notifier-bats -L && just check`
Expected: the check builds; `nix flake check` passes (module still evaluates — the notifier script text changed but the packaging in `default.nix` is unchanged aside from comments).

- [ ] **Step 9: Commit**

```bash
git add modules/desktop/update-checks/hyprflake-updates.sh \
        modules/desktop/update-checks/default.nix \
        modules/desktop/update-checks/tests/notifier.bats flake.nix
git commit -S -m "fix(update-checks): re-scope DMS advisory to nixpkgs-caught-up; name commands"
```

---

## Task 5: Docs + final CI

**Files:**
- Modify: `docs/workarounds.md` (DMS section, ~line 120)

- [ ] **Step 1: Update the DMS workaround section**

In `docs/workarounds.md`, the "DankMaterialShell pinned ahead of nixpkgs for Lua dispatch" section: change "pinned to a master commit" to "pinned to the v1.5.0 release tag", and set **Remove when:** to "nixpkgs' `dms-shell` reaches the pinned version — the `hyprflake-updates` timer now flags this automatically; then drop the `dank-material-shell` input override and restore `package = pkgs.dms-shell`." Keep the symptom/cause text.

- [ ] **Step 2: Run the full CI pipeline**

Run: `just ci`
Expected: `fmt lint check eval` all pass, ending with "✅ All CI checks passed".

- [ ] **Step 3: Commit**

```bash
git add docs/workarounds.md
git commit -S -m "docs(workarounds): reframe DMS pin as v1.5.0 tag + auto-flagged override"
```

---

## Self-Review notes

- **Spec coverage:** resolver (Task 1), `just bump` one + no-arg (Tasks 2–3), re-scoped + command-naming notifier (Task 4), single-source resolver shared by bump and notifier (Tasks 1 + 4 Step 3's `api`/resolver reuse), coverage generality (bump-input is generic; widening the watch list is data — noted, deferred), docs (Task 5). The spec's optional `updates.tsv` machine-readable companion is **intentionally dropped** (YAGNI): no-arg `just bump` iterates inputs directly, removing a workstation-state dependency for a repo-side command. Flag for the user during plan review.
- **Placeholder scan:** every code/test step contains full content; no TBD/TODO.
- **Type/name consistency:** `resolve-latest <repo> <mode>` with `mode ∈ {tag,sha}` is used identically in Tasks 1, 2 (stub), and 4; `bump-input [--skip-branch] <input> [flake]` used identically in Tasks 2 and 3; message command strings (`just bump <input>`, `just update-input <input>`) consistent across notifier messages.
