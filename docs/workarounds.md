# Workarounds

Active, hyprflake-side patches for upstream-side bugs. Each entry pins
the fix location, the upstream issue/PR to watch, and the signal that
says it's safe to remove.

**Revisit on every `nixpkgs` bump** — especially when the bump touches
`greetd`, `hyprpolkitagent`, or the `dank-material-shell` greeter input.

---

## DankGreeter preStart exposes user config paths to the `greeter` user

- **Symptom:** none at runtime. This is a security exposure, not a
  visible failure. It applies whenever the DankGreeter is the login
  manager, which on hyprflake is always (the greeter is core, no toggle).
- **Cause:** the upstream greeter's `greetd` `preStart` runs as root,
  reads the user's `settings.json` / `session.json` (synced via
  `configHome`), then copies the file paths they reference
  (`customThemeFile`, `wallpaperPath*`, `monitorWallpapers*`) into
  `/var/lib/dms-greeter` and runs `chown greeter:` over the result
  (assuming the default `greeter` greetd session user, which hyprflake
  does not override). Any path written into those JSON files is followed
  by root and the copy is handed to the unprivileged `greeter` user. The `customThemeFile` copy
  is also how Stylix theming reaches the greeter, so it cannot simply be
  dropped without losing the themed login screen.
- **Impact:** bounded under the single-user threat model. The writer of
  the DMS config is the primary user, so the realistic risk is something
  running as that user planting a root-only path (e.g. a key file) and
  getting a `greeter`-readable copy. Not a remote or cross-user vector.
- **Fix location:** upstream `distro/nix/greeter.nix` `preStart`. The
  right fix is upstream validating that the referenced paths resolve
  under the user's own DMS state dir before copying, and dropping the
  blanket `chown greeter:`. Not patched hyprflake-side because
  reimplementing the preStart via `mkForce` is fragile across DMS bumps.
- **Upstream:** file an issue against `AvengeMedia/DankMaterialShell`.
- **Remove when:** the upstream greeter sandboxes path resolution in its
  `preStart`. **Revisit on every DMS input bump.**

---

## `hyprpolkitagent` autostarts in the greetd greeter and ABRTs

- **Symptom:** Hyprpolkit ABRT crash loop inside the greetd `greeter`
  user session (`Failed to create wl_display`); after 5 restarts hits
  `start-limit-hit`, tears the greeter session down → blank login
  screen.
- **Cause:** Upstream `hyprpolkitagent.service` ships
  `WantedBy=graphical-session.target`, which fires in **any** graphical
  user session including the greetd greeter, where the agent may have no
  Hyprland wl_display to attach to.
- **Fix:** `modules/desktop/hyprland/default.nix` —
  `systemd.user.services.hyprpolkitagent.unitConfig.ConditionGroup = "!greeter";`
- **Upstream:** same class of bug as
  [nixpkgs#347651](https://github.com/NixOS/nixpkgs/issues/347651) for
  `hypridle`. Canonical fix proposed in
  [nixpkgs#355416](https://github.com/NixOS/nixpkgs/pull/355416) (uses
  `ConditionEnvironment=XDG_SESSION_DESKTOP=Hyprland`, endorsed by
  fufexan) but unmerged. We use `ConditionGroup` instead because it's
  UWSM-independent (the greetd greeter runs as user `greeter`, primary
  group `greeter`; regular users do not).
- **Verify:** this guard was repointed from the GDM greeter group to the
  greetd `greeter` group during the GDM-to-DankGreeter migration. Confirm
  on the consuming system that hyprpolkitagent does not crash-loop in the
  greeter session and starts normally in the user session.
- **Remove when:** the upstream `hyprpolkitagent.service` unit drops
  `WantedBy=graphical-session.target` in favour of a Hyprland-specific
  target, **or** nixpkgs#355416 (or equivalent) merges and ships the
  gating for both `hypridle` and `hyprpolkitagent`.

---

## `hyprctl dispatch <legacy>` silently fails under Hyprland Lua backend

- **Symptom:** Keybinds in third-party tools that shell out to
  `hyprctl dispatch workspace 1`, `hyprctl dispatch dpms off`,
  `hyprctl dispatch focuswindow title:Foo`, etc. silently no-op.
  Manual invocation from a terminal prints
  `error: return hl.dispatch(...): ')' expected near '...'` plus the
  hint *"dispatch in lua is a shorthand for hl.dispatch(...), your
  syntax might need to be updated."*
- **Cause:** Hyprland 0.55's Lua config backend rewrites
  `hyprctl dispatch <X>` as a Lua eval of `hl.dispatch(<X>)`
  (`src/debug/HyprCtl.cpp:1102-1117`). The legacy hyprlang dispatch
  arg syntax becomes invalid Lua.
- **Fix:** `modules/system/hyprctl-compat/` installs a Python wrapper at
  `bin/hyprctl` (with `lib.hiPrio` so it shadows `pkgs.hyprland`'s
  binary). It intercepts the `dispatch` subcommand and `--batch`
  segments, rewrites the legacy form to lua via a static translation
  table, and execs the real hyprctl. Direct-IPC callers are NOT helped
  (see the next entry for waybar).
- **Upstream:** filed/discussed at
  [hyprwm/Hyprland#14255](https://github.com/hyprwm/Hyprland/discussions/14255).
  Vaxerski explicitly rejected adding a backwards-compat shim — calls
  the new behaviour "expected." No upstream fix coming.
- **Remove when:** every shell-based caller of `hyprctl dispatch` in
  your ecosystem has migrated to lua dispatch syntax. The wrapper is
  pure transition aid; it costs one extra `execv` per `hyprctl` call.

---

## Waybar's `hyprland/workspaces` click no-ops under Lua backend (RESOLVED)

- **Resolved by the DankMaterialShell migration.** Waybar (and its
  `waybar-hyprland-lua` overlay) was removed when the desktop shell moved to
  DankMaterialShell. The overlay and `programs.waybar.package` override no
  longer exist. See `docs/superpowers/specs/2026-06-01-dank-material-shell-migration-design.md`.
- Historical context: waybar's `hyprland/workspaces` module called the Hyprland
  IPC socket with hardcoded legacy dispatch strings that the Lua backend
  rejected, so hyprflake shipped a `substituteInPlace` overlay
  (`pkgs.waybar-hyprland-lua`). DMS's bar uses its own IPC, so the patch is
  moot.

---

## DankMaterialShell pinned to a master commit for Lua dispatch (active)

- **Symptom:** clicking a workspace in the DMS bar and selecting a window
  from the overview/exposé silently do nothing. DMS logs show
  `Dispatch request "workspace 3" failed ... return hl.dispatch(workspace 3)
  ... ')' expected near '3'`.
- **Cause:** DMS talks to the Hyprland IPC socket directly (via Quickshell),
  bypassing `system/hyprctl-compat`. Under the Lua config backend Hyprland
  evaluates dispatch requests as Lua, so the legacy `workspace N` /
  `focuswindow …` strings that nixpkgs' `dms-shell` (1.4.6) sends fail to
  parse — the same root cause as the resolved waybar entry above. DMS fixed
  it on `master` (1.5-beta): `HyprlandService.qml` emits `hl.dsp.*` Lua-form
  dispatch. No release tag carries the fix yet (latest is v1.4.6).
- **Fix:** `flake.nix` pins `dank-material-shell` to a frozen master commit
  (a SHA, not the `master` branch, so `nix flake update` can't drift it), and
  `modules/desktop/dank/default.nix` consumes
  `…packages.<system>.dms-shell` from that input instead of `pkgs.dms-shell`.
  Quickshell stays on nixpkgs (the DMS flake no longer ships it).
- **Upstream:** fixed in DMS `master`; no issue to file. Track releases for
  when the fix ships in a tag.
- **Remove when:** a DMS *release* carries the `hl.dsp.*` dispatch — check
  with `just dms-check`. Then pin that tag in `flake.nix`; once nixpkgs'
  `dms-shell` reaches it, restore `package = pkgs.dms-shell` and drop both the
  flake-package override and the master pin.
