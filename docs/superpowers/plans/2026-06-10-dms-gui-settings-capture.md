# DMS GUI Settings Capture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hyprflake.desktop.dank.capture` — a feature that seeds a writable, layered DMS `settings.json`, lets the GUI edit it, and round-trips changes into the consumer repo via an explicit `dank-capture` command, with a clobber-guard against data loss.

**Architecture:** hyprflake's hardcoded `settings` becomes the default of an overridable option. The effective config = `recursiveUpdate <settings> <capture.overrides>`. When `capture.enable`, the DMS read-only symlink is suppressed and a `home.activation` script seeds a real writable `settings.json` (plus a read-only base reference and a canonical-hash marker). A bundled Python tool does deep-diff/merge/canonical-hash; thin shell wrappers (`dank-capture`/`dank-discard`/`dank-diff`/`dank-seed`) drive the round-trip.

**Tech Stack:** Nix (home-manager module, `pkgs.formats.json`, `writeShellApplication`), Python 3 (pure diff/merge logic), pytest + bats (tests).

**Spec:** `docs/superpowers/specs/2026-06-10-dms-gui-settings-capture-design.md`

---

## File Structure

```
modules/desktop/dank/
  default.nix                 # MODIFY: settings→option, capture options, suppress symlink, wire activation+packages
  capture/
    default.nix               # CREATE: builds the tool + CLIs, exposes seedCommand + rendered files
    diff.py                   # CREATE: canonical/hash/diff/merge/equal (pure logic)
    seed.sh                   # CREATE: activation seed + clobber-guard
    dank-capture.sh           # CREATE: live→repo delta capture
    dank-discard.sh           # CREATE: reset live to Nix-rendered config
    dank-diff.sh              # CREATE: dry-run of what capture would write
    tests/
      test_diff.py            # CREATE: pytest for diff.py
      seed.bats              # CREATE: bats for seed.sh guard
flake.nix                     # MODIFY: add checks.<system>.{dank-diff-pytest,dank-seed-bats}
docs/options.md               # MODIFY: document the capture option + consumer wiring
```

**Baseline note:** the diff baseline (`.dank-defaults.json`) is the rendered `settings` option — i.e. hyprflake defaults **plus** consumer Nix overrides, but **without** `capture.overrides`. So the captured delta is exactly the cumulative GUI contribution, and `merge(base, overrides) == live`.

---

## Task 1: Core Python tool — canonical & hash

**Files:**
- Create: `modules/desktop/dank/capture/diff.py`
- Test: `modules/desktop/dank/capture/tests/test_diff.py`

- [ ] **Step 1: Write the failing test**

```python
# modules/desktop/dank/capture/tests/test_diff.py
import importlib.util
import os

_spec = importlib.util.spec_from_file_location(
    "diff", os.path.join(os.path.dirname(__file__), "..", "diff.py")
)
diff = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(diff)


def test_canonical_is_order_independent():
    a = {"b": 1, "a": [3, 2]}
    b = {"a": [3, 2], "b": 1}
    assert diff.canonical(a) == diff.canonical(b)


def test_canonical_list_order_is_significant():
    assert diff.canonical([1, 2]) != diff.canonical([2, 1])
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: FAIL — `diff.py` not found / no `canonical`.

- [ ] **Step 3: Write minimal implementation**

```python
# modules/desktop/dank/capture/diff.py
#!/usr/bin/env python3
"""DMS settings delta/merge/canonicalisation tool.

Subcommands:
  canonical <file>    print canonical JSON (sorted keys, compact)
  hash <file>         print sha256 of canonical JSON
  diff <base> <live>  print minimal delta D with merge(base, D) == live
  merge <base> <over> print recursiveUpdate(base, over)
  equal <a> <b>       exit 0 if canonical(a) == canonical(b) else 1
"""
import hashlib
import json
import sys


def load(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def canonical(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: PASS (2 passed).

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/capture/diff.py modules/desktop/dank/capture/tests/test_diff.py
git commit -S -m "feat(dank): add canonical JSON helper for settings capture"
```

---

## Task 2: Python tool — deep_merge

**Files:**
- Modify: `modules/desktop/dank/capture/diff.py`
- Test: `modules/desktop/dank/capture/tests/test_diff.py`

- [ ] **Step 1: Write the failing test**

```python
def test_deep_merge_recurses_dicts():
    base = {"a": {"x": 1, "y": 2}, "b": 9}
    over = {"a": {"y": 3}}
    assert diff.deep_merge(base, over) == {"a": {"x": 1, "y": 3}, "b": 9}


def test_deep_merge_replaces_lists_wholesale():
    base = {"bars": [{"id": "a"}, {"id": "b"}]}
    over = {"bars": [{"id": "c"}]}
    assert diff.deep_merge(base, over) == {"bars": [{"id": "c"}]}


def test_deep_merge_adds_new_keys():
    assert diff.deep_merge({"a": 1}, {"b": 2}) == {"a": 1, "b": 2}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: FAIL — `deep_merge` not defined.

- [ ] **Step 3: Write minimal implementation**

Append to `diff.py`:

```python
def deep_merge(base, over):
    if isinstance(base, dict) and isinstance(over, dict):
        out = dict(base)
        for k, v in over.items():
            out[k] = deep_merge(base[k], v) if k in base else v
        return out
    return over
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: PASS (5 passed).

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/capture/diff.py modules/desktop/dank/capture/tests/test_diff.py
git commit -S -m "feat(dank): add recursiveUpdate-equivalent deep_merge"
```

---

## Task 3: Python tool — deep_diff + round-trip invariant

**Files:**
- Modify: `modules/desktop/dank/capture/diff.py`
- Test: `modules/desktop/dank/capture/tests/test_diff.py`

- [ ] **Step 1: Write the failing test**

```python
def test_deep_diff_minimal_and_nested():
    base = {"a": {"x": 1, "y": 2}, "b": 9}
    live = {"a": {"x": 1, "y": 5}, "b": 9}
    assert diff.deep_diff(base, live) == {"a": {"y": 5}}


def test_deep_diff_new_key_and_changed_list():
    base = {"bars": [1, 2]}
    live = {"bars": [1, 2, 3], "extra": True}
    assert diff.deep_diff(base, live) == {"bars": [1, 2, 3], "extra": True}


def test_deep_diff_identical_is_empty():
    base = {"a": {"x": 1}}
    assert diff.deep_diff(base, {"a": {"x": 1}}) == {}


def test_roundtrip_merge_of_diff_equals_live():
    base = {"a": {"x": 1, "y": 2}, "bars": [1, 2], "b": 9}
    live = {"a": {"x": 1, "y": 5}, "bars": [9], "b": 9, "new": "z"}
    delta = diff.deep_diff(base, live)
    assert diff.canonical(diff.deep_merge(base, delta)) == diff.canonical(live)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: FAIL — `deep_diff` not defined.

- [ ] **Step 3: Write minimal implementation**

Append to `diff.py`:

```python
_UNCHANGED = object()


def _diff(base, live):
    """Return delta value, or _UNCHANGED sentinel when nothing changed."""
    if isinstance(base, dict) and isinstance(live, dict):
        delta = {}
        for k, v in live.items():
            if k not in base:
                delta[k] = v
            else:
                d = _diff(base[k], v)
                if d is not _UNCHANGED:
                    delta[k] = d
        return delta if delta else _UNCHANGED
    return live if canonical(base) != canonical(live) else _UNCHANGED


def deep_diff(base, live):
    d = _diff(base, live)
    return {} if d is _UNCHANGED else d
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: PASS (9 passed).

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/capture/diff.py modules/desktop/dank/capture/tests/test_diff.py
git commit -S -m "feat(dank): add minimal deep_diff with merge round-trip invariant"
```

---

## Task 4: Python tool — CLI dispatch (canonical/hash/diff/merge/equal)

**Files:**
- Modify: `modules/desktop/dank/capture/diff.py`
- Test: `modules/desktop/dank/capture/tests/test_diff.py`

- [ ] **Step 1: Write the failing test**

```python
import json
import subprocess


def _run(tmp_path, *args, files=None):
    files = files or {}
    paths = []
    for name, obj in files.items():
        p = tmp_path / name
        p.write_text(json.dumps(obj))
        paths.append(str(p))
    cmd = ["python3", os.path.join(os.path.dirname(__file__), "..", "diff.py"), *args, *paths]
    return subprocess.run(cmd, capture_output=True, text=True)


def test_cli_hash_is_canonical(tmp_path):
    r1 = _run(tmp_path, "hash", files={"a.json": {"a": 1, "b": 2}})
    r2 = _run(tmp_path, "hash", files={"b.json": {"b": 2, "a": 1}})
    assert r1.returncode == 0
    assert r1.stdout.strip() == r2.stdout.strip()


def test_cli_equal_exit_codes(tmp_path):
    same = _run(tmp_path, "equal", files={"a.json": {"x": 1}, "b.json": {"x": 1}})
    diff_ = _run(tmp_path, "equal", files={"a.json": {"x": 1}, "b.json": {"x": 2}})
    assert same.returncode == 0
    assert diff_.returncode == 1
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: FAIL — diff.py has no CLI / prints nothing / non-zero.

- [ ] **Step 3: Write minimal implementation**

Append to `diff.py`:

```python
def main(argv):
    cmd = argv[1] if len(argv) > 1 else ""
    if cmd == "canonical":
        print(canonical(load(argv[2])))
        return 0
    if cmd == "hash":
        print(hashlib.sha256(canonical(load(argv[2])).encode("utf-8")).hexdigest())
        return 0
    if cmd == "diff":
        print(json.dumps(deep_diff(load(argv[2]), load(argv[3])), indent=2, sort_keys=True))
        return 0
    if cmd == "merge":
        print(json.dumps(deep_merge(load(argv[2]), load(argv[3])), indent=2, sort_keys=True))
        return 0
    if cmd == "equal":
        return 0 if canonical(load(argv[2])) == canonical(load(argv[3])) else 1
    sys.stderr.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd modules/desktop/dank/capture && python3 -m pytest tests/test_diff.py -q`
Expected: PASS (11 passed).

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/capture/diff.py modules/desktop/dank/capture/tests/test_diff.py
git commit -S -m "feat(dank): add CLI dispatch to settings tool"
```

---

## Task 5: Seed + clobber-guard script

**Files:**
- Create: `modules/desktop/dank/capture/seed.sh`
- Test: `modules/desktop/dank/capture/tests/seed.bats`

- [ ] **Step 1: Write the failing test**

```bash
# modules/desktop/dank/capture/tests/seed.bats
setup() {
  TMP="$(mktemp -d)"
  export TMP
  # Stub tool: 'hash' prints sha256 of raw bytes (sufficient for guard tests).
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/dank-settings-tool" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "hash" ] && { sha256sum "$2" | cut -d' ' -f1; exit 0; }
exit 2
EOF
  chmod +x "$TMP/bin/dank-settings-tool"
  export PATH="$TMP/bin:$PATH"
  printf '{"v":1}\n' > "$TMP/effective.json"
  printf '{"v":0}\n' > "$TMP/base.json"
  SEED="${BATS_TEST_DIRNAME}/../seed.sh"
  export SEED
}
teardown() { rm -rf "$TMP"; }

@test "seeds when target absent and records marker" {
  run bash "$SEED" "$TMP/effective.json" "$TMP/base.json" \
      "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [ -f "$TMP/settings.json" ]
  [ -f "$TMP/marker" ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'"v": 1'* ]] || [[ "$output" == *'"v":1'* ]]
}

@test "re-seeds when live matches marker" {
  bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  printf '{"v":2}\n' > "$TMP/effective.json"   # new generation
  run bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'2'* ]]
}

@test "preserves live and warns when marker mismatches" {
  bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  printf '{"v":99,"edited":true}\n' > "$TMP/settings.json"   # GUI edit
  printf '{"v":2}\n' > "$TMP/effective.json"
  run bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"un-captured"* ]]
  run cat "$TMP/settings.json"
  [[ "$output" == *"edited"* ]]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats modules/desktop/dank/capture/tests/seed.bats`
Expected: FAIL — `seed.sh` does not exist.

- [ ] **Step 3: Write minimal implementation**

```bash
# modules/desktop/dank/capture/seed.sh
#!/usr/bin/env bash
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
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats modules/desktop/dank/capture/tests/seed.bats`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/capture/seed.sh modules/desktop/dank/capture/tests/seed.bats
git commit -S -m "feat(dank): add settings seed script with clobber-guard"
```

---

## Task 6: CLI wrappers (capture / discard / diff)

**Files:**
- Create: `modules/desktop/dank/capture/dank-capture.sh`
- Create: `modules/desktop/dank/capture/dank-discard.sh`
- Create: `modules/desktop/dank/capture/dank-diff.sh`

> These are driven through Nix substitution: `@repoPath@` and `@effectiveFile@`
> are replaced when the `writeShellApplication`s are built in Task 7. They are
> committed as source here; Task 7 wires and build-tests them.

- [ ] **Step 1: Write `dank-capture.sh`**

```bash
# modules/desktop/dank/capture/dank-capture.sh
#!/usr/bin/env bash
# Capture live GUI edits into the consumer repo as a minimal delta.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
ref="$cfg/.dank-defaults.json"
marker="$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"
repo="@repoPath@"

[ -e "$ref" ] || { echo "No base reference at $ref. Rebuild in capture mode first." >&2; exit 1; }
[ -e "$target" ] || { echo "No settings.json at $target." >&2; exit 1; }

mkdir -p "$(dirname "$repo")"
dank-settings-tool diff "$ref" "$target" > "$repo.tmp"
mv "$repo.tmp" "$repo"
# Bless current live state as captured so the next rebuild re-seeds cleanly.
dank-settings-tool hash "$target" > "$marker"

echo "Captured DMS overrides -> $repo"
echo "Changed top-level keys:"
dank-settings-tool diff "$ref" "$target" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join("  "+k for k in sorted(d)) or "  (none)")'
echo "Next: commit $repo and run your rebuild."
```

- [ ] **Step 2: Write `dank-discard.sh`**

```bash
# modules/desktop/dank/capture/dank-discard.sh
#!/usr/bin/env bash
# Drop un-captured GUI edits: reset settings.json to the Nix-rendered config.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
marker="$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"

mkdir -p "$cfg" "$(dirname "$marker")"
install -m644 "@effectiveFile@" "$target"
dank-settings-tool hash "$target" > "$marker"
echo "Discarded un-captured GUI edits; settings.json reset to the Nix-rendered config."
```

- [ ] **Step 3: Write `dank-diff.sh`**

```bash
# modules/desktop/dank/capture/dank-diff.sh
#!/usr/bin/env bash
# Dry-run: show the delta dank-capture would write, without mutating anything.
set -euo pipefail

cfg="$HOME/.config/DankMaterialShell"
target="$cfg/settings.json"
ref="$cfg/.dank-defaults.json"

[ -e "$ref" ] && [ -e "$target" ] || { echo "Rebuild in capture mode first." >&2; exit 1; }
dank-settings-tool diff "$ref" "$target"
```

- [ ] **Step 4: Verify scripts are syntactically valid**

Run: `bash -n modules/desktop/dank/capture/dank-capture.sh modules/desktop/dank/capture/dank-discard.sh modules/desktop/dank/capture/dank-diff.sh`
Expected: no output, exit 0.

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/capture/dank-capture.sh modules/desktop/dank/capture/dank-discard.sh modules/desktop/dank/capture/dank-diff.sh
git commit -S -m "feat(dank): add capture/discard/diff CLI wrapper scripts"
```

---

## Task 7: Capture Nix module — build tool, CLIs, seed command

**Files:**
- Create: `modules/desktop/dank/capture/default.nix`

- [ ] **Step 1: Write `capture/default.nix`**

```nix
# modules/desktop/dank/capture/default.nix
#
# Pure builder for the DMS settings-capture feature. Given the rendered
# `effective` settings, the `base` settings (defaults + consumer Nix, the diff
# baseline), and the consumer's absolute `repoPath`, returns the packages to put
# on PATH and the activation command that seeds settings.json.
{ pkgs, lib, effective, base, repoPath }:
let
  jsonFmt = pkgs.formats.json { };
  effectiveFile = jsonFmt.generate "dank-effective.json" effective;
  baseFile = jsonFmt.generate "dank-base.json" base;

  dankTool = pkgs.writeShellApplication {
    name = "dank-settings-tool";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${./diff.py} "$@"'';
  };

  dankSeed = pkgs.writeShellApplication {
    name = "dank-seed";
    runtimeInputs = [ dankTool pkgs.coreutils ];
    text = builtins.readFile ./seed.sh;
  };

  subst = text:
    builtins.replaceStrings
      [ "@repoPath@" "@effectiveFile@" ]
      [ repoPath "${effectiveFile}" ]
      text;

  mkCli = name: src: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ dankTool pkgs.python3 pkgs.coreutils ];
    text = subst (builtins.readFile src);
  };

  dankCapture = mkCli "dank-capture" ./dank-capture.sh;
  dankDiscard = mkCli "dank-discard" ./dank-discard.sh;
  dankDiff = mkCli "dank-diff" ./dank-diff.sh;
in
{
  packages = [ dankTool dankSeed dankCapture dankDiscard dankDiff ];

  seedCommand = lib.concatStringsSep " " [
    "${dankSeed}/bin/dank-seed"
    "${effectiveFile}"
    "${baseFile}"
    ''"$HOME/.config/DankMaterialShell/settings.json"''
    ''"$HOME/.config/DankMaterialShell/.dank-defaults.json"''
    ''"$HOME/.local/state/DankMaterialShell/.dank-seed.sha256"''
  ];
}
```

- [ ] **Step 2: Verify it evaluates and builds the CLIs**

Run:
```bash
nix eval --impure --expr '
  let pkgs = import <nixpkgs> {}; lib = pkgs.lib;
      cap = import ./modules/desktop/dank/capture {
        inherit pkgs lib;
        effective = { v = 1; bars = [ 1 2 ]; };
        base = { v = 0; bars = [ 1 2 ]; };
        repoPath = "/tmp/overrides.json";
      };
  in builtins.length cap.packages'
```
Expected: `5`

- [ ] **Step 3: Build the tool and exercise the round-trip**

Run:
```bash
TOOL=$(nix build --impure --no-link --print-out-paths --expr '
  let pkgs = import <nixpkgs> {}; lib = pkgs.lib;
  in (import ./modules/desktop/dank/capture {
       inherit pkgs lib;
       effective = {}; base = {}; repoPath = "/tmp/x";
     }).packages')
echo '{"a":{"x":1},"b":2}' > /tmp/base.json
echo '{"a":{"x":9},"b":2,"c":3}' > /tmp/live.json
"$TOOL"/bin/dank-settings-tool diff /tmp/base.json /tmp/live.json
```
Expected: JSON `{"a": {"x": 9}, "c": 3}`

> Note: `nix build` on a list returns the first element's path; the command
> above pins `dankTool` first in `packages`. If your nix returns all outputs,
> adapt the path. This step only sanity-checks the bundled tool.

- [ ] **Step 4: Commit**

```bash
git add modules/desktop/dank/capture/default.nix
git commit -S -m "feat(dank): add capture module building tool, CLIs and seed command"
```

---

## Task 8: Options — make `settings` overridable, add `capture`

**Files:**
- Modify: `modules/desktop/dank/default.nix` (the `options` block near line 30, and the `let` block at top)

- [ ] **Step 1: Add the options**

In `modules/desktop/dank/default.nix`, extend the `let` block to alias the new config path, and replace the single `options.hyprflake.desktop.search.enable = …` line with an `options` attrset that ADDS the new options (keep the existing search option intact):

```nix
  # add to the top-level `let … in`
  cfg = config.hyprflake.desktop.dank;
  jsonFmt = pkgs.formats.json { };
```

```nix
  options = {
    hyprflake.desktop.search.enable =
      lib.mkEnableOption "the DankSearch (dsearch) indexed file-search backend for the DMS launcher" // { default = true; };

    hyprflake.desktop.dank.settings = lib.mkOption {
      type = jsonFmt.type;
      description = "Base DMS settings. hyprflake provides the default; consumers may deep-merge overrides in pure Nix, and GUI captures merge on top.";
      default = {
        # MOVE the entire existing inline `settings = { … };` attrset here
        # verbatim (acLockTimeout … barConfigs …). It already references `idle`,
        # `searchCfg`, `batteryOr`, and `config.hyprflake.system.isLaptop`,
        # which remain in scope.
      };
    };

    hyprflake.desktop.dank.capture = {
      enable = lib.mkEnableOption "GUI-editable, repo-backed DMS settings (writable settings.json + dank-capture round-trip)";

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "/home/dustin/git/nixerator/hosts/donkeykong/dank/overrides.json";
        description = "Absolute working-tree path where dank-capture writes the overrides delta. Required when capture.enable is true.";
      };

      overrides = lib.mkOption {
        type = jsonFmt.type;
        default = { };
        description = "GUI-captured override delta, imported at eval time and merged last. Typically `lib.importJSON ./hosts/<host>/dank/overrides.json` guarded by builtins.pathExists.";
      };
    };
  };
```

- [ ] **Step 2: Add the assertion (inside `config = { … }`)**

```nix
    assertions = [
      {
        assertion = !cfg.capture.enable || cfg.capture.repoPath != "";
        message = "hyprflake.desktop.dank.capture.enable requires capture.repoPath to be set (absolute path to overrides.json in your repo).";
      }
    ];
```

- [ ] **Step 3: Verify options evaluate (no consumer change yet)**

Run: `nix flake check --no-build 2>&1 | tail -20` (or build a host that imports the module)
Expected: evaluation succeeds; no assertion triggered (capture defaults off).

- [ ] **Step 4: Commit**

```bash
git add modules/desktop/dank/default.nix
git commit -S -m "feat(dank): expose settings as overridable option and add capture options"
```

---

## Task 9: Wire effective settings, suppress symlink in capture mode, seed + packages

**Files:**
- Modify: `modules/desktop/dank/default.nix` (the `home-manager.sharedModules` inline module, lines ~38-281)

- [ ] **Step 1: Compute effective + capture builder in the `let` block**

```nix
  effective = lib.recursiveUpdate cfg.settings cfg.capture.overrides;
  capture = import ./capture {
    inherit pkgs lib effective;
    base = cfg.settings;
    repoPath = cfg.capture.repoPath;
  };
```

- [ ] **Step 2: Replace the inline `settings = { … };` assignment**

The DMS home module only writes the read-only `settings.json` symlink when
`cfg.settings != {}` (`distro/nix/home.nix`). So:

```nix
        programs.dank-material-shell = {
          # … all existing options unchanged (enable, package, quickshell, plugins, …) …

          # When capture is OFF: write the effective settings as today's
          # read-only symlink. When ON: leave it empty so the DMS module skips
          # the symlink; the activation script below seeds a writable file.
          settings = lib.mkIf (!cfg.capture.enable) effective;
        };
```

(Delete the old literal `settings = { … barConfigs … };` block — its content now lives in the option default from Task 8.)

- [ ] **Step 3: Add capture packages + activation (still inside the same inline home module)**

```nix
        home.packages =
          [ pkgs.gh ]                                   # existing
          ++ lib.optionals cfg.capture.enable capture.packages;

        home.activation = lib.mkIf cfg.capture.enable {
          dankSeedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] capture.seedCommand;
        };
```

- [ ] **Step 4: Build a host to verify both modes evaluate**

Run:
```bash
nix eval .#nixosConfigurations --apply 'builtins.attrNames' 2>/dev/null || true
# Then build the toplevel of a host that imports dank (capture still off):
nix build .#nixosConfigurations.<somehost>.config.system.build.toplevel --no-link 2>&1 | tail -5
```
Expected: builds; non-capture path unchanged (settings.json still a symlink).

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/dank/default.nix
git commit -S -m "feat(dank): seed writable settings.json and ship capture CLIs when enabled"
```

---

## Task 10: Flake checks for the Python + bats tests

**Files:**
- Modify: `flake.nix` (add `checks` outputs)

- [ ] **Step 1: Inspect how outputs are produced**

Run: `grep -nE "outputs|forAllSystems|flake-utils|flake-parts|perSystem|eachSystem|checks" flake.nix | head`
Expected: identifies the per-system mechanism (e.g. `flake-utils.lib.eachSystem` or a `forAllSystems` helper).

- [ ] **Step 2: Add two checks using that mechanism**

Add a `checks.<system>` attrset (adapt the wrapper to the mechanism found in Step 1). The derivations:

```nix
dank-diff-pytest = pkgs.runCommand "dank-diff-pytest"
  { nativeBuildInputs = [ pkgs.python3 pkgs.python3Packages.pytest ]; } ''
  cp -r ${./modules/desktop/dank/capture} capture
  chmod -R u+w capture
  cd capture && python3 -m pytest tests/test_diff.py -q
  touch $out
'';

dank-seed-bats = pkgs.runCommand "dank-seed-bats"
  { nativeBuildInputs = [ pkgs.bats pkgs.coreutils ]; } ''
  cp -r ${./modules/desktop/dank/capture} capture
  chmod -R u+w capture
  cd capture && bats tests/seed.bats
  touch $out
'';
```

- [ ] **Step 3: Run the checks**

Run: `nix build .#checks.x86_64-linux.dank-diff-pytest .#checks.x86_64-linux.dank-seed-bats --no-link`
Expected: both build (tests pass).

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -S -m "test(dank): add flake checks for settings capture tool and seed guard"
```

---

## Task 11: Documentation — option reference + consumer wiring

**Files:**
- Modify: `docs/options.md`

- [ ] **Step 1: Add a capture section**

Append to `docs/options.md`:

```markdown
## DMS settings capture (`hyprflake.desktop.dank.capture`)

By default `hyprflake.desktop.dank.settings` is rendered to a read-only
`~/.config/DankMaterialShell/settings.json` symlink — the DMS GUI shows a
"read-only" banner and changes do not persist.

Enable capture to make the GUI the editing surface and round-trip changes into
your repo:

```nix
hyprflake.desktop.dank.capture = {
  enable = true;
  repoPath = "/home/<you>/git/<repo>/hosts/<host>/dank/overrides.json";
  overrides =
    let f = ./dank/overrides.json;
    in if builtins.pathExists f then lib.importJSON f else { };
};
```

Workflow:

1. Edit settings in the DMS GUI (now writable, persists across reboot).
2. Run `dank-capture` — writes only your delta to `overrides.json`.
3. Commit `overrides.json` and rebuild. Per key: your override wins, else the
   hyprflake default.

Helpers: `dank-diff` (dry-run), `dank-discard` (drop un-captured edits). A
rebuild made with un-captured GUI edits is refused with a warning rather than
overwriting them. `barConfigs` overridden purely in Nix still needs `mkForce`
(lists do not deep-merge); the GUI/capture path handles it automatically.
```

- [ ] **Step 2: Commit**

```bash
git add docs/options.md
git commit -S -m "docs(dank): document settings capture option and workflow"
```

---

## Self-Review notes (addressed)

- **Spec coverage:** options (Task 8) ✓; writable seed + symlink suppression (Task 9) ✓; clobber-guard (Task 5) ✓; diff baseline `.dank-defaults.json` = rendered `settings` (Task 7/9) ✓; CLIs capture/discard/diff (Tasks 6-7) ✓; precedence default<Nix<captured via `recursiveUpdate cfg.settings cfg.capture.overrides` (Task 9) ✓; assertion on repoPath (Task 8) ✓; backward compat via `mkIf (!cfg.capture.enable)` (Task 9) ✓; tests (Tasks 1-5, 10) ✓; docs + consumer wiring (Task 11) ✓.
- **Known limitation (documented in spec):** key *removal* in the GUI is not expressible as a `recursiveUpdate` delta — a removed key reappears from defaults. Not tested for equality; acceptable for v1.
- **Type consistency:** tool subcommands `canonical|hash|diff|merge|equal` used identically across diff.py, seed.sh, and the CLIs; `effectiveFile`/`baseFile`/`seedCommand`/`packages` names match between `capture/default.nix` and `dank/default.nix`.
```
