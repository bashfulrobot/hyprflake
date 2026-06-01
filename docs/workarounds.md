# Workarounds

Active, hyprflake-side patches for upstream-side bugs. Each entry pins
the fix location, the upstream issue/PR to watch, and the signal that
says it's safe to remove.

**Revisit on every `nixpkgs` bump** — especially when the bump touches
`nixos/modules/services/display-managers/gdm.nix`, the `gnome-session`
package, or `hyprpolkitagent`.

---

## GDM 50 greeter cannot find `gnome-session`

- **Symptom:** post-boot, blank login screen. Journal:
  `gdm-wayland-session[...]: Unable to run session`.
- **Cause:** GDM 50's greeter session file ships `Exec=gnome-session`,
  but nixpkgs' `gdm.nix` only adds `pkgs.gnome-session` to the
  display-manager service's `PATH=` env, not to
  `environment.systemPackages`. The `gdm-greeter` user therefore can't
  find the binary.
- **Fix:** `modules/desktop/display-manager/default.nix` —
  `environment.systemPackages = [ pkgs.gnome-session ];`
- **Upstream:** no nixpkgs issue filed yet (PR opportunity).
- **Remove when:** nixpkgs `gdm.nix` adds `pkgs.gnome-session` to its
  own `environment.systemPackages` (currently it only adds
  `adwaita-icon-theme` and `pkgs.gdm`).

---

## GDM 50 greeter cannot find `gnome-login.session`

- **Symptom:** post-boot, blank login screen. Journal:
  `gnome-session-manager@gnome-login.service: Failed with result 'protocol'`,
  `Failed to fill session`.
- **Cause:** GDM 50's greeter is now a full `gnome-session` invocation
  that calls `gsm_session_fill → find_valid_session_keyfile` to locate
  `gnome-login.session` via `XDG_DATA_DIRS`. nixpkgs adds
  `${sessionData.desktops}/share` to system-wide `XDG_DATA_DIRS` (so
  `wayland-sessions/hyprland.desktop` is found) but **not** `${gdm}/share`
  or `${gnome-session}/share` — so the session keyfile in
  `gnome-session/sessions/` is unreachable.
- **Fix:** `modules/desktop/display-manager/default.nix` —
  ```nix
  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gdm}/share"
    "${pkgs.gnome-session}/share"
  ];
  ```
- **Upstream:** no nixpkgs issue filed yet (PR opportunity).
- **Remove when:** nixpkgs `gdm.nix` adds `${pkgs.gdm}/share` and
  `${pkgs.gnome-session}/share` to
  `environment.sessionVariables.XDG_DATA_DIRS` alongside the existing
  `${sessionData.desktops}/share` entry.

---

## `hyprpolkitagent` autostarts in the GDM greeter and ABRTs

- **Symptom:** Hyprpolkit ABRT crash loop inside the gdm-greeter user
  session (`Failed to create wl_display`); after 5 restarts hits
  `start-limit-hit`, tears the greeter session down → blank login
  screen.
- **Cause:** Upstream `hyprpolkitagent.service` ships
  `WantedBy=graphical-session.target`, which fires in **any** graphical
  user session including GDM's greeter. The greeter has no Hyprland
  compositor for the agent to attach to.
- **Fix:** `modules/desktop/hyprland/default.nix` —
  `systemd.user.services.hyprpolkitagent.unitConfig.ConditionGroup = "!gdm";`
- **Upstream:** same class of bug as
  [nixpkgs#347651](https://github.com/NixOS/nixpkgs/issues/347651) for
  `hypridle`. Canonical fix proposed in
  [nixpkgs#355416](https://github.com/NixOS/nixpkgs/pull/355416) (uses
  `ConditionEnvironment=XDG_SESSION_DESKTOP=Hyprland`, endorsed by
  fufexan) but unmerged. We use `ConditionGroup` instead because it's
  UWSM-independent (gdm-greeter and gdm-greeter-{1..4} all share
  primary group `gdm`; regular users do not).
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
