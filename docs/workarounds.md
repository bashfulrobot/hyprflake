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

## Waybar's `hyprland/workspaces` click no-ops under Lua backend

- **Symptom:** Clicking workspace pills in the waybar `hyprland/workspaces`
  module with `on-click = "activate"` no longer switches workspaces.
  Keybindings still work; waybar logs `Failed to dispatch workspace`.
- **Cause:** Waybar's `src/modules/hyprland/workspace.cpp:74-87` calls
  the Hyprland IPC socket directly with hardcoded legacy dispatch
  strings (`"dispatch workspace " + id`, `"dispatch togglespecialworkspace " + name`,
  etc.). Direct IPC bypasses the `hyprctl` binary, so the `hyprctl-compat`
  wrapper cannot fix this — the patch has to land in waybar itself.
- **Fix:** `modules/desktop/waybar/default.nix` ships a `nixpkgs.overlays`
  entry providing `pkgs.waybar-hyprland-lua`, a `substituteInPlace` of
  the six hardcoded dispatch strings to emit lua form
  (`hl.dsp.focus({workspace=N})`, `hl.dsp.workspace.toggle_special("...")`,
  etc.). The waybar module sets `programs.waybar.package =
  pkgs.waybar-hyprland-lua`.
- **Upstream:** open as
  [Alexays/Waybar#5008](https://github.com/Alexays/Waybar/issues/5008)
  and [#5035](https://github.com/Alexays/Waybar/issues/5035). No PR in
  flight at the time of writing.
- **Remove when:** waybar upstream ships lua-aware Hyprland dispatch
  (either an explicit `hyprland-lua` module variant, or a runtime
  config-type detection in the existing module).
