# DankMaterialShell migration design

Replace hyprflake's waybar-based desktop shell with DankMaterialShell (DMS) on a
feature branch, testable in isolation from `~/git/nixerator` and reversible by
repointing a single flake input. Tracks issue #17.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Target shell | DankMaterialShell (DMS), Quickshell/QML, `/stable` line |
| Cutover model | Hard cutover on the branch. `main` stays waybar. |
| Scope | Full shell replacement in one cut |
| Lock + idle | Adopt DMS bundled locker + idle; retire hyprlock + hypridle |
| Edge tools | Replace aggressively |
| Emoji picker (rofimoji) | Dropped |
| Shortcut cheat-sheet | Rewritten as a Stylix-themed HTML page opened in the browser |
| Cheat-sheet content | Option B: live `hyprctl binds -j` rendered into a build-time Stylix-themed template on each open. Styling cannot drift; the bind list is always current and captures consumer `conf.d/*.lua` binds (e.g. nixerator's special-workspaces, ncspot-save) with no migration |
| DMS package | Prefer prebuilt `pkgs.dms-shell`; fall back to flake source build |
| Wallpaper | DMS owns it (retire hyprpaper); Stylix feeds the image |
| Autostart | DMS systemd user service (`systemd.enable = true`), no `exec-once` |
| Idle ladder | lock 300s, screen-off/DPMS 360s, suspend 600s; lock before suspend |
| Screen-off | Must actually blank displays on idle. Disabled today (dpms unreliable under hypridle); reliable DPMS under DMS is a hard requirement, not a nice-to-have |
| Theming | Stylix remains the single source of truth |

## Consumption and rollback model

nixerator pins `hyprflake.url = "github:bashfulrobot/hyprflake"` (`flake.nix:42`)
and imports `inputs.hyprflake.nixosModules.default` on two hosts. Two test paths
against this branch:

1. **Local override (fast inner loop, no push).** Rebuild nixerator with
   `--override-input hyprflake path:/home/dustin/git/.worktrees/feat-17-dank-shell`.
   Instant iteration, nothing leaves the machine.
2. **Branch input (the rollback model).** Push the branch, set
   `hyprflake.url = "github:bashfulrobot/hyprflake/feat/17-dank-shell"` in
   nixerator `flake.nix`, run `nix flake update hyprflake`, rebuild. **Rollback =
   revert that one line + `nix flake update hyprflake`.**

For path 2 to stay a single-line change, the branch must not remove any hyprflake
option nixerator sets. Hence the compatibility principle below.

## Consumer-eval compatibility principle

Options that removed modules defined and that nixerator references stay declared on
the branch as no-op deprecation stubs (`lib.mkOption` plus a `warnings` entry), so
nixerator evaluates unchanged. Known consumer touch-points to stub:

- `hyprflake.desktop.waybar.*` — used by `lib/mkWebApp.nix:75`
  (`workspaceAppIcons.rewrites`) and the desktop suite.
- `hyprflake.desktop.hyprshell.*` — desktop suite notes it as always-enabled.
- Any swaync / swayosd / rofi / wlogout / waybar.autoHide enable toggles the suite
  sets.

`hyprflake.desktop.shortcutsViewer.*` is NOT stubbed; that module is rewritten in
place, so its option surface survives naturally.

Stubs emit a build warning ("waybar removed in favor of DMS; option is a no-op") so
the dead options are easy to find and clean out of nixerator later.

## What gets removed (functionality, not option names)

Nine modules lose their packages/services/styling (~2,000 lines): waybar,
waybar-auto-hide, swaync, swayosd, rofi, rofimoji, wlogout, hyprshell, plus
hyprlock and hypridle (DMS locker + idle adopted). shortcuts-viewer is rewritten,
not removed.

## What gets added

- Flake input `dank-material-shell` (`/stable`), inputs following nixpkgs and
  home-manager, threaded through `hyprflakeInputs`.
- `modules/desktop/dank/` — imports DMS's `homeModules.dank-material-shell` via
  `home-manager.sharedModules`, enables it, sets feature toggles, package override
  (`pkgs.dms-shell` when available), and `systemd.enable = true`.
- Stylix: `stylix.targets.dank-material-shell.enable = true` and
  `enableDynamicTheming = false` so matugen does not fight Stylix base16.
- Hyprland keybind rewrites to `dms ipc` (table below), DMS autostart, removal of
  dead `$menu` / swaync / swayosd / wlogout references.
- shortcuts-viewer rewrite: build-time Stylix-themed HTML template + a wrapper that
  renders `hyprctl binds -j` into it and opens via `xdg-open`.

## Keybind remap (current to DMS IPC)

| Action | Current | New |
|---|---|---|
| App launcher | rofi (SUPER+Space) | `dms ipc spotlight toggle` |
| Notifications | swaync-client (SUPER+N) | `dms ipc notifications toggle` |
| Power menu | wlogout (SUPER+Esc) | `dms ipc powermenu toggle` |
| Lock | hyprlock | `dms ipc lock lock` |
| Volume up/down/mute | swayosd-client | `dms ipc audio increment/decrement/mute` |
| Mic mute | swayosd-client | `dms ipc audio micmute` |
| Brightness up/down | swayosd-client | `dms ipc brightness increment/decrement 5 ""` |
| Clipboard history | (new) | `dms ipc clipboard toggle` |
| Network | rofi-network-manager (SUPER+I) | DMS control center (verify exact IPC target at runtime) |
| Shortcut cheat-sheet | rofi/fzf (SUPER+/) | `xdg-open` themed HTML page |
| Emoji picker | rofimoji (SUPER+.) | removed; SUPER+. freed |

## Stylix wiring

Stylix's DMS HM target maps base16 to Material-3, sets fonts/opacity, writes the
wallpaper path, and pins `currentThemeName = "custom"`. We additionally set
`enableDynamicTheming = false` so the runtime palette cannot drift from declared
base16. The HTML cheat-sheet template injects `config.lib.stylix.colors` and
`config.stylix.fonts` at build time, matching the existing `mkStyle` pattern.

## Implementation phases

1. **Stubs first** — add deprecation stubs for consumer-referenced options so
   nixerator never breaks mid-migration.
2. **Flake input + DMS module** — add the input, write `modules/desktop/dank/`,
   register in `modules/default.nix`.
3. **Stylix wiring** — enable the DMS target, disable dynamic theming.
4. **Hyprland rewrites** — remap binds to `dms ipc`, add DMS autostart, drop dead
   client references; DMS owns the wallpaper (hyprpaper retired).
5. **shortcuts-viewer rewrite** — HTML template + render-and-open wrapper.
6. **Remove the nine modules + hyprlock/hypridle** (functionality), keeping stub
   declarations only.
7. **Gate** — `nixpkgs-fmt`, `statix`, `deadnix`, `nix flake check`; files end with
   a blank line.

## Validation / acceptance

- hyprflake `nix flake check` passes on the branch.
- nixerator evaluates against the branch with zero option errors (proves the stub
  principle).
- Local-override rebuild of nixerator boots Hyprland with DMS bar, launcher,
  notifications, OSD, power menu, lock, and idle all functional.
- Lock-before-suspend confirmed (no suspend to an unlocked session).
- Stylix colors/fonts/wallpaper visibly applied to DMS; no matugen drift.
- Cheat-sheet opens in the browser, themed, listing live binds including
  consumer-added conf.d binds.
- Rollback drill: revert the input line, rebuild, confirm the waybar shell returns.

## Validation results (2026-06-01, headless)

- `nix flake check` on the branch: passes.
- nixerator `qbert` full eval against the branch (`--override-input hyprflake
  path:<worktree>`): succeeds, zero option errors. Only the nine expected
  deprecation warnings fire. The stub principle holds; nixerator needs no edits.
- Build dry-run: `quickshell` and `dms-shell` compile from source on the current
  nixpkgs pin (their Qt deps are cache-fetched); everything else is trivial. A
  full source build and on-hardware runtime checks (screen-off wake, theming)
  remain (Task 10), to be done at the machine.

## Known limitations / follow-ups

- **calendar-notifier** was removed entirely in this migration since it hooked
  the retired swaync daemon and was disabled in the only consumer. Re-adding
  fullscreen calendar takeovers later would require porting it to DMS's
  notification system. Documented in `docs/options.md`.

## Risks and open items

- **DMS package availability.** `pkgs.dms-shell` presence in the pinned nixpkgs is
  unconfirmed; implementation verifies and falls back to the flake build.
- **Hyprland IPC coverage.** DMS declarative helpers are niri-only; all Hyprland
  binds are hand-wired. The network IPC target needs a runtime check.
- **Brightness/volume backend.** swayosd carried udev rules and video/input group
  membership. Confirm DMS brightness/volume keys work; re-add `brightnessctl` or
  group membership if required.
- **Lua backend justification.** Lua was originally adopted for hyprshell's runtime
  `eval hl.bind`. Removing hyprshell removes that reason, but lua stays as the
  repo standard.
- **Merge to main later.** Hard cutover means merging drops waybar for good.
  Acceptable as the sole consumer, but a conscious call when the time comes.

## Out of scope

- Adding a runtime `hyprflake.desktop.shell` selector (waybar | dank). Hard cutover
  was chosen; a selector can be revisited if main ever needs to offer both.
- A `hyprflake.desktop.keybinds` registry feeding a static build-time cheat sheet
  (Option A). Considered and rejected. Option B captures consumer `conf.d` binds
  with no registry refactor and no nixerator migration.
- Migrating non-shell modules (kitty, gtk, voxtype, power, keyring).

## Post-merge cleanup (do when the branch lands on main)

Much of the migration is transitional compatibility scaffolding kept so
nixerator evaluates with a one-line rollback. Once DMS is validated on hardware
and the branch merges to main, sweep both repos in this order (consumer first,
then hyprflake, so eval never breaks):

1. **nixerator** — drop the now-ignored option usage:
   `hyprflake.desktop.waybar.workspaceAppIcons.*` (in `lib/mkWebApp.nix` and the
   desktop suite) and `hyprflake.desktop.waybar.autoHide`. Confirm nothing else
   sets the deprecated `desktop.{swaync,swayosd,rofi,rofimoji,wlogout,hyprshell,
   hyprlock,hypridle}.enable` options.
2. **hyprflake** — delete `modules/desktop/waybar/`, `modules/desktop/waybar-auto-hide/`,
   and `modules/desktop/deprecated-stubs.nix` (and their imports in
   `modules/default.nix`). waybar is gone with the new shell; it is not a keeper.
3. **shortcuts-viewer** — drop the `mkRenamedOptionModule` aliases for the old
   `hyprflake.shortcuts-viewer.*` path (`shortcuts-viewer/default.nix:32-40`) once
   no consumer uses the legacy path.
4. **hyprctl-compat** — re-evaluate whether `system/hyprctl-compat` is still
   needed. In-repo callers were rewritten to lua dispatch form; if only external
   consumer scripts still rely on the legacy `hyprctl dispatch` syntax, decide
   whether to keep the shim or sunset it.
5. **Bluetooth utility** — if the on-hardware test confirms DMS's control center
   provides Bluetooth pairing (an agent + manager), remove `blueman` and its
   `services.blueman.enable` from `hyprland/default.nix`. Kept for now because a
   pairing agent is a real functional dependency that could not be verified
   headlessly.

### DMS-first: revisit kept tools as DMS evolves

The standing principle for this desktop is **DMS-first**: prefer DankMaterialShell's
built-in capability over a standalone tool whenever DMS provides it. The tools
below were kept only because DMS does not (yet) cover them or coverage is
unverified. Loop back periodically, re-test against the current DMS, and drop
the ones it has caught up on:

- `pwvucontrol` — full per-app PipeWire mixer (DMS audio is basic volume).
- `impala` — WiFi TUI fallback (DMS control center does network).
- `playerctl` — backs the media-key scripts; revisit if DMS exposes media-key IPC.
- `blueman` — see item 5 above.
