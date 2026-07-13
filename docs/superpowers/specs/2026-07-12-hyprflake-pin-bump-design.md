# hyprflake pin-bump workflow — design

One-command bumping of hyprflake's tag/SHA-pinned flake inputs, driven by a
trustworthy update notifier. Turns "the notifier reminded me, now I hand-edit
`flake.nix`" into "the notifier named the command, I run it."

## Problem

hyprflake pins most of its DankMaterialShell-ecosystem and tooling inputs to a
**literal ref** in `flake.nix` — a release tag (`dank-material-shell` →
`.../v1.5.0`, `voxtype` → a tag) or a commit SHA (`dms-emoji-launcher`,
`dms-github-notifier`, `dms-command-runner`, `dms-calculator`, `dms-plugins`,
`danksearch`, …). `nix flake update` / `just update-input` only re-resolve the
*same* ref, so they cannot move a literal tag/SHA forward. Advancing one means
hand-editing the URL in `flake.nix`, then re-locking, then committing.

A systemd user timer (`modules/desktop/update-checks/`) runs
`hyprflake-updates.sh`, which polls GitHub and fires a desktop notification when
a pinned upstream has moved. It is the reminder to go do that hand-edit. Two
gaps make it painful:

1. **The hand-edit is manual and easy to get wrong** (right file, right line,
   right ref format, then re-lock).
2. **The notifier's signal is not fully trustworthy.** The DMS advisory block
   (`hyprflake-updates.sh` lines ~45–51) fires *unconditionally* whenever the
   latest DMS release carries the `hl.dsp.focus` Lua-dispatch fix. That was the
   "drop the master pin" prompt — but the pin was already switched to the
   `v1.5.0` tag (commit 51b5551), so the message now fires forever describing an
   action already taken. A reminder you must learn to ignore trains you to
   ignore all of them.

## Goals

- A single command, `just bump <input>`, that rewrites the pinned ref in
  `flake.nix` to the latest upstream, re-locks, shows the diff, and stops —
  leaving commit/release to the existing flow.
- Every notification the checker emits is genuinely actionable and names the
  exact command to run.
- No hand-editing of `flake.nix` for a routine pin bump.

## Non-goals

- Auto-commit, auto-release, auto-merge, or auto-rebuild. The trigger is always
  a human running `just bump`. (Chosen explicitly: keep control, kill tedium.)
- Changing how workstations *consume* hyprflake. That stays, in nixerator,
  `just update hyprflake && just qr` — untouched.
- Managing nixpkgs / home-manager currency. Branch-tracking inputs already move
  with `just update`; this design does not replace that.

## Design

Three parts: a shared resolver, a `just bump` recipe, and a trustworthy checker.

### Part 1 — `resolve-latest.sh` (shared resolver, single source of truth)

New: `modules/desktop/update-checks/resolve-latest.sh <input-name>`. Given an
input name, it prints the latest upstream ref that input *should* pin, plus the
pin mode, on stdout:

```
tag  v0.9.0
sha  1269b4688cc94cbd271e1cbbf19a6e7caa2293de
```

Mode is derived from the input's current ref shape in `flake.nix`:

- **tag mode** — current ref is a semver tag (`vX.Y.Z`). Resolve the repo's
  latest release tag via the GitHub releases API.
- **sha mode** — current ref is a 40-hex commit SHA. Resolve the default
  branch's HEAD SHA (`commits/HEAD`, so the branch name is not hardcoded).
- **branch mode** — current ref is a branch name or absent (`nixpkgs`,
  `home-manager`, `stylix`, …). Print `branch <name>`; these move with
  `nix flake update` and are out of `bump`'s hand-edit scope.

Both the checker and the bump recipe call this one script, so "what should input
X resolve to" is defined in exactly one place and the two cannot drift.

### Part 2 — `just bump <input>` (and `just bump` = all flagged)

```
just bump dank-material-shell     # one input
just bump                         # every input the checker currently flags
```

Behaviour for one input:

1. Call `resolve-latest.sh <input>` to get `(mode, ref)`.
2. **branch mode** → delegate to `just update-input <input>` (re-lock the
   branch) and report; no `flake.nix` edit.
3. **tag/sha mode** → rewrite only the `url = "...<ref>"` line for that input in
   `flake.nix` to the new ref (targeted line edit scoped to that input's block,
   not a blind global replace).
4. `nix flake lock --update-input <input>` to re-lock.
5. Print the `git diff` of `flake.nix` + `flake.lock` and stop. No commit.

No-arg `just bump` asks the checker for the current set of flagged inputs (see
Part 3's machine-readable output) and bumps each. Still no commit; you review
the combined diff, then commit + `just release` as usual.

### Part 3 — trustworthy, actionable checker

Edit `hyprflake-updates.sh`:

- **Re-scope the DMS advisory.** Delete the unconditional "drop the master pin"
  block. Replace it with the genuinely-pending next step: fire only when
  nixpkgs' `dms-shell` reaches the version hyprflake currently pins from the
  flake input — i.e. *"nixpkgs now ships dms-shell <ver>; drop the flake-input
  override and restore `pkgs.dms-shell` (modules/desktop/dank)."* That is the
  real remaining action behind the current input override, and it stops firing
  once done.
- **Name the command in every message.** Each actionable line ends with the
  exact command, e.g. `voxtype v0.9.0 released — run: just bump voxtype`.
- **Emit a machine-readable companion.** Alongside the human `updates.txt`,
  write `updates.tsv` (one `input<TAB>mode<TAB>ref` row per flagged input) so
  no-arg `just bump` has a precise work-list instead of re-deriving it.
- **Reuse `resolve-latest.sh`** for the tag/SHA comparisons it does inline
  today, so the checker and `bump` agree by construction.

## Coverage

The checker today watches 4 signals: DankMaterialShell, Hyprland (via
nixos-unstable `package.nix`), `dms-emoji-launcher`, `voxtype`. Because
`resolve-latest.sh` and `just bump` are **generic over any tag/SHA-pinned
input**, extending the watch list is data, not code: add the other SHA-pinned
DMS-ecosystem inputs (`dms-github-notifier`, `dms-command-runner`,
`dms-calculator`, `dms-plugins`, `danksearch`) to the checker's list and they
gain both notification and one-command bump for free. Doing so is an in-scope
follow-on; the core deliverable is the resolver + `bump` + the two checker
fixes.

## End-to-end loop after this lands

1. Timer fires a notification: *"voxtype v0.9.0 released — run: just bump
   voxtype."*
2. In `~/git/hyprflake`: `just bump voxtype` → review diff → commit →
   `just release`.
3. In `~/git/nixerator`: `just update hyprflake && just qr`.

No hand-editing; every notification is real.

## Testing

- `resolve-latest.sh`: unit-test mode detection against sample `flake.nix` ref
  shapes (semver tag → tag, 40-hex → sha, branch name → branch). Network calls
  stubbed.
- `just bump <input>`: on a scratch copy of `flake.nix`, assert the correct
  single `url` line changes and `flake.lock` re-locks to the new ref; assert a
  branch-mode input delegates to `update-input` and leaves `flake.nix`
  unchanged.
- Checker: assert the re-scoped DMS message does **not** fire when the input
  already tracks the fixed tag, and **does** fire when nixpkgs `dms-shell`
  catches up; assert every emitted line carries a `just bump …` command and a
  matching `updates.tsv` row.
- `just health` / `just check` stay green.

## Open questions

- `just release` semantics after a bump: leave fully manual (this design), or
  offer `just bump <input> --release` later? Deferred — start manual.
- Whether to widen the watch list now or in a follow-on PR. Design supports
  either; default to core-first.
