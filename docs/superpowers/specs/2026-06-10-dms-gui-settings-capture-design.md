# DMS GUI-editable, repo-backed settings (`hyprflake.desktop.dank.capture`)

A hyprflake feature that lets a consumer tune DankMaterialShell from its own
GUI and have those changes persist and round-trip back into the consumer's Nix
repo, while hyprflake continues to supply per-key defaults. The GUI becomes the
editing surface; the repo becomes the source of truth; hyprflake is the
fallback for anything the user has not overridden.

## Problem

hyprflake's dank module hardcodes `programs.dank-material-shell.settings = {…}`.
The DMS home-manager module renders that to a **read-only `/nix/store` symlink**
at `~/.config/DankMaterialShell/settings.json`. DMS detects writability with
`[ -w settings.json ]`, which follows the symlink into the store, reports
read-only, and shows the GUI banner *"Settings are read-only. Changes will not
persist."* The user cannot tune the shell from its own GUI, and any value not
exposed by hyprflake cannot be set at all without editing hyprflake.

DMS has **no native layering** — there is a single `settings.json` `FileView`
(`quickshell/Common/SettingsData.qml`). `session.json`
(`~/.local/state/DankMaterialShell/`) is a *different* bucket (light mode, DND,
weather location, terminal override) that DMS writes freely and hyprflake does
not manage; it does not hold the structural settings (bar layout, auto-hide,
idle ladder) that the read-only banner is blocking. So "base + override" must be
built by us.

## Goals

1. **GUI is the editing surface** — no read-only banner, no thaw ritual; edits
   persist across reboot.
2. **Per-key fallback layering** — a key set in the consumer's repo wins; every
   other key falls through to the hyprflake default. hyprflake default upgrades
   keep reaching the user for keys they have not overridden.
3. **Built into hyprflake as a first-class feature** — shipped to every
   consumer behind one toggle, not bespoke per-consumer tooling.
4. **Explicit, predictable capture** — nothing mutates the consumer's git tree
   until the user runs a command. No silent data loss on rebuild.

## Non-goals (v1 scope boundary)

- `settings.json` only. `session.json` is already writable and needs nothing.
  `plugin_settings.json` stays declarative-by-design (plugins are reviewed as
  code; see the dank module comment). `clsettings.json` out of scope.
- No automatic capture (on GUI save or on rebuild). Rejected for predictability.
- No three-way reconciliation of two simultaneously-edited sources (hand-edited
  `overrides.json` *and* un-captured GUI edits) — the guard refuses and asks the
  user to pick one.

## Mental model (consumer's point of view)

1. Edit settings in the DMS GUI — it just works, no banner, persists.
2. Run `dank-capture` when happy → changes land in
   `<repo>/hosts/<host>/dank/overrides.json`.
3. Commit + `nixos-rebuild`. Overrides win per key; hyprflake supplies the rest.

Three of those steps are already routine; only `dank-capture` is new.

## Architecture

```
GUI edit ─writes→ ~/.config/DankMaterialShell/settings.json   (writable, merged)
                          │
        dank-capture  diff vs  ~/.config/DankMaterialShell/.dank-defaults.json
                          │ (minimal delta)
                          ▼
   <repo>/hosts/<host>/dank/overrides.json  ──committed, eval-time import──┐
                                                                           │
hyprflake defaults ─recursiveUpdate→ consumer-Nix ─recursiveUpdate→ overrides ─seed→┘
                          ▲
              canonical-hash clobber-guard
```

### Options (new, in `modules/desktop/dank/default.nix`)

```nix
hyprflake.desktop.dank = {
  # Was the inline `settings = {…}`. Now the overridable DEFAULT. The current
  # hardcoded value (idle ladder, showWorkspaceIndex, barConfigs, …) becomes
  # this option's `default`, computed from hyprflake.desktop.idle / isLaptop as
  # today. Consumers may deep-merge overrides in pure Nix.
  settings = lib.mkOption {
    type = (pkgs.formats.json { }).type;
    default = <existing computed settings>;
    description = "Base DMS settings. hyprflake defaults; consumer Nix may override; GUI captures merge on top.";
  };

  capture = {
    enable = lib.mkEnableOption "GUI→repo capture round-trip for DMS settings.json";

    # ABSOLUTE working-tree path the capture CLI writes at runtime. Differs from
    # the eval-time relative flake path below because Nix reads the file from the
    # store while the CLI writes the live checkout.
    repoPath = lib.mkOption {
      type = lib.types.str;
      example = "/home/dustin/git/nixerator/hosts/donkeykong/dank/overrides.json";
      description = "Absolute path in the consumer repo where dank-capture writes the overrides delta.";
    };

    # EVAL-time import of the committed delta. Consumer sets
    # `overrides = if builtins.pathExists ./hosts/<host>/dank/overrides.json
    #              then lib.importJSON ./hosts/<host>/dank/overrides.json else {}`
    # (hyprflake provides a helper / documents this one-liner).
    overrides = lib.mkOption {
      type = (pkgs.formats.json { }).type;
      default = { };
      description = "GUI-captured override delta, imported at eval time and merged last.";
    };
  };
};
```

**Precedence (last wins):** hyprflake default → consumer Nix (`settings.*`) →
GUI-captured (`capture.overrides`). The effective config is:

```nix
effective = lib.recursiveUpdate config.hyprflake.desktop.dank.settings
                                config.hyprflake.desktop.dank.capture.overrides;
```

`config…settings` already folds hyprflake defaults ⊕ consumer Nix via normal
module merge; `capture.overrides` is a single definition `recursiveUpdate`d on
top in code (not module-merged), so it cleanly replaces lists such as
`barConfigs`.

### Materialization (home-manager, only when `capture.enable`)

- Set `programs.dank-material-shell.settings = {}` so the **DMS module stops
  emitting the read-only symlink** — it guards on `lib.mkIf (cfg.settings != {})`
  (`distro/nix/home.nix`).
- A `home.activation` entry `lib.hm.dag.entryAfter ["writeBoundary"]` seeds:
  - `~/.config/DankMaterialShell/settings.json` — **real, mode 644**, content =
    `effective` rendered JSON. Writable, so DMS's `[ -w ]` check passes and the
    banner disappears.
  - `~/.config/DankMaterialShell/.dank-defaults.json` — mode 444, content =
    hyprflake **pure defaults** (the `settings` option value *without*
    `capture.overrides`). Diff baseline for the CLI.
  - `~/.local/state/DankMaterialShell/.dank-seed.sha256` — canonical-hash marker
    (see guard).

Ordering: must run before the `dms` user service is (re)started so DMS reads the
freshly seeded file.

### Clobber-guard (canonical-JSON hash, formatting-proof)

Raw byte hashing is unreliable: `recursiveUpdate` + `toJSON` key ordering will
not match DMS's atomic-write output, so a semantic no-op would look like an edit.
The marker therefore stores the hash of **canonicalized** JSON (sorted keys,
normalized whitespace — `jq -S` or `python -c json.dumps(...,sort_keys=True)`).

On each rebuild activation:

| Condition | Action |
|---|---|
| live file absent | seed `effective`; marker = `canonHash(effective)` |
| `canonHash(live) == marker` | no un-captured edits → re-seed `effective`; marker = `canonHash(effective)` |
| `canonHash(live) != marker` | un-captured GUI edits → **preserve live, warn**, do not overwrite |

Warning text: *"DMS settings.json has un-captured GUI edits — run `dank-capture`
to save them into your repo, or `dank-discard` to drop them."*

This makes frequent `nixos-rebuild` safe between a GUI tweak and a capture.

### CLI (shipped on PATH via `home.packages` when `capture.enable`)

Implemented as `writeShellApplication`s parameterized with the config dir and
`capture.repoPath`; deep-diff/canonicalization done by a small bundled `python3`
helper (jq recursive diff is awkward).

- **`dank-capture`** — deep-diff `live` against `.dank-defaults.json` producing
  a **minimal delta** (recurse objects; leaf included when it differs from or is
  absent in defaults; **lists compared and replaced wholesale**, matching
  `recursiveUpdate` semantics). Write delta → `repoPath` (`mkdir -p` parents).
  Bless marker = `canonHash(live)` so the next rebuild sees `live == marker` and
  re-seeds cleanly. Print the changed keys and "now commit + rebuild." Errors if
  `.dank-defaults.json` is missing ("rebuild in capture mode first").
- **`dank-discard`** — re-seed `live` from `effective`, reset marker; reverts
  un-captured GUI edits.
- **`dank-diff`** — dry-run; print what `dank-capture` would write, no mutation.

#### Delta round-trip invariant

`recursiveUpdate(defaults, diff(defaults, live)) == live` (semantically, under
canonicalization). After `dank-capture` + rebuild, `effective` is semantically
equal to the captured `live`, so the post-capture rebuild re-seeds a no-op and
the marker stays consistent.

### Edge cases

- `capture.enable` without `repoPath` → eval-time `assertion` with a fix hint.
- No `overrides.json` → `capture.overrides = {}` via `pathExists` guard → pure
  defaults (and consumer Nix overrides).
- Malformed `overrides.json` → `importJSON` fails the build loudly (it is the
  user's committed file; surfacing the parse error is correct).
- Hand-edited `overrides.json`, no un-captured GUI edits (`live == marker`) →
  rebuild applies the new merge cleanly; hand-editing the repo works.
- Hand-edited `overrides.json` **and** un-captured GUI edits (`live != marker`)
  → guard refuses + warns; user runs `dank-capture` (live wins, overwrites the
  hand edit) or `dank-discard` (repo wins). Documented, not auto-reconciled.
- DMS atomic writes (temp + rename) replace the inode but keep the path; the
  guard reads by path, unaffected.
- Multi-host: `.dank-defaults.json` and the marker live under `$HOME`, naturally
  per-machine; each host sets its own `repoPath` + `overrides`.
- `barConfigs` pure-Nix override still needs `mkForce` (two list definitions
  cannot module-merge). The GUI/`capture.overrides` path avoids this. Listed as a
  future enhancement (expose `barConfigs` as its own structured option).

### Backward compatibility

`capture.enable = false` (default) → today's behavior exactly: hyprflake sets
`programs.dank-material-shell.settings` and the DMS module renders the read-only
symlink. Existing consumers are untouched.

## Consumer (nixerator) wiring

Per host, e.g. `donkeykong`:

```nix
hyprflake.desktop.dank.capture = {
  enable = true;
  repoPath = "/home/dustin/git/nixerator/hosts/donkeykong/dank/overrides.json";
  overrides =
    let f = ./dank/overrides.json;
    in if builtins.pathExists f then lib.importJSON f else { };
};
```

(hyprflake documents/help-wraps the `pathExists`/`importJSON` one-liner.)

## Testing

- **Nix eval** — absent / empty / populated `overrides`; precedence (default <
  consumer Nix < captured); `barConfigs` replaced by captured override.
- **Script units** — `recursiveUpdate(defaults, diff(defaults, live)) == live`;
  canonicalization stable across key-order permutations; minimal-delta
  correctness (unchanged keys absent; changed/new keys present; lists wholesale).
- **Guard** — absent-file → seed; `live == marker` → re-seed; `live != marker`
  → preserve + warn (assert exit/stderr).
- **Manual** — rebuild in capture mode → no banner → toggle Auto-hide →
  `dank-capture` → `overrides.json` contains the bar delta → rebuild → setting
  persists → toggle again without capture → rebuild → warning printed, setting
  preserved → `dank-discard` → reverts.

## Implementation note

The feature is a hyprflake change (new options, activation seeding, CLI
package, guard); nixerator only *consumes* it via the wiring above. Ships as a
hyprflake PR.
