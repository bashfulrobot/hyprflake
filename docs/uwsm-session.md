# UWSM Session Wiring

How a login becomes a running graphical session, why `withUWSM = true` is
mandatory, and the stale-greeter-pin failure mode that silently kills the dank
shell. Read this when the shell / wallpaper / polkit agent don't start after
login, or when reasoning about `graphical-session.target`.

## The short version

`greetd` (the DankGreeter login manager) is deliberately minimal: unlike GDM it
does **not** set up the systemd user graphical session, import the environment,
or activate `graphical-session.target`. **UWSM does that job.** Every per-session
service in hyprflake — `dms.service` (the shell), `hyprpaper`, `snappy-switcher`,
`voxtype`, `wl-clip-persist`, `hyprpolkitagent`, the keyring units — is
`WantedBy=graphical-session.target` (see `lib/systemd-helpers.nix`
`mkGraphicalUserService`). If that target never activates, none of them start and
the desktop comes up bare.

Because `withUWSM = true` also turns **off** home-manager's own Hyprland systemd
integration (`modules/desktop/hyprland/default.nix`, the
`!(config.programs.hyprland.withUWSM or false)` gate), **UWSM is the *only* thing
that activates `graphical-session.target`. There is no fallback.**

## The two session entries

The nixpkgs Hyprland package installs **two** files in
`/run/current-system/sw/share/wayland-sessions/`, and DankGreeter lists both:

| Desktop file | `Name` | `Exec` | Activates UWSM? |
|---|---|---|---|
| `hyprland-uwsm.desktop` | Hyprland (uwsm-managed) | `uwsm start -e -D Hyprland hyprland.desktop` | **yes** |
| `hyprland.desktop` | Hyprland | `start-hyprland` (execs `Hyprland` directly) | **no** |

`start-hyprland` is the Hyprland package's native launcher — a small binary that
just `execvp`s `Hyprland`. It contains no UWSM logic. Picking this entry produces
a working compositor but **no managed session**: `graphical-session.target` stays
dead and the whole service cluster above never starts.

With **no saved choice**, DankGreeter's `finalizeSessionSelection()` defaults to
the alphabetically-first entry. `hyprland-uwsm.desktop` sorts before
`hyprland.desktop` (`-` = 0x2d < `.` = 0x2e), so the safe UWSM entry is the
default. The trap is the *saved* choice — see "Failure mode" below.

## The UWSM unit chain (what actually activates the session)

When `uwsm start -e -D Hyprland hyprland.desktop` runs, UWSM drives this graph of
user units (all installed as `linked-runtime` templates; `%i` =
`hyprland.desktop`):

```
uwsm start ─┐
            ├─ wayland-session-pre@%i.target      (environment prep)
            │     └─ wayland-wm-env@%i.service     (exports env into the
            │                                        user manager + D-Bus)
            ├─ wayland-wm@%i.service                ExecStart=uwsm aux exec -- Hyprland
            │     Requires=wayland-session-pre@%i.target
            │     BindsTo=wayland-session@%i.target
            │     Before=wayland-session@%i.target graphical-session.target
            │     → THIS is the process that runs the compositor
            └─ wayland-session@%i.target
                  Requires=wayland-session-pre@%i.target wayland-wm@%i.service
                  BindsTo=graphical-session.target        ◀── the hinge
                  Before=graphical-session.target
                  PropagatesStopTo=graphical-session.target
```

The single line that matters: **`wayland-session@hyprland.desktop.target` carries
`BindsTo=graphical-session.target` + `Before=graphical-session.target`.** Reaching
the wayland-session target therefore pulls up `graphical-session.target`, which
pulls in `dms.service` and the rest. `wayland-session-bindpid@%i.service` ties the
session's lifetime to the greetd-supplied PID so logout tears everything down
cleanly via `PropagatesStopTo`.

Net: **compositor runs as `wayland-wm@hyprland.desktop.service`, not as a bare
child of greetd.** That is the fingerprint of a healthy UWSM session.

## Failure mode: stale greeter session pin

**Symptom:** after login the bar/shell, wallpaper, and polkit prompts are all
missing. `dms.service` shows "No entries" for the boot — systemd never even tried
to start it.

**Root cause (NOT a config regression):** DankGreeter remembers the last-selected
session in `/var/lib/dms-greeter/.local/state/memory.json` (`lastSessionId`;
`rememberLastSession` defaults true — `GreetdMemory.qml`). When no session is
remembered, `finalizeSessionSelection()` (`GreeterContent.qml`) falls back to
`sessionList[0]`, the first-enumerated session — the UWSM entry, since
`hyprland-uwsm.desktop` sorts before `hyprland.desktop`. But once the plain
`hyprland.desktop` is selected, its `lastSessionId` is replayed: greetd execs
`start-hyprland`, none of the `wayland-*` units activate, and
`graphical-session.target` stays dead.

How sticky the pin is depends on whether the greetd preStart resets
`/var/lib/dms-greeter` (observed 2026-06-13: a reboot defaulted back to UWSM
without clearing anything), so it does not necessarily recur on every reboot —
but a single stray pick is enough to lose the shell for that session. Do **not**
"fix" it by setting `withUWSM = false` — that removes the UWSM units entirely and
breaks the *default* (UWSM) login path into a greeter crash-loop. The config is
correct; the runtime pin is wrong.

**Hardening (wired in):** the display-manager module sets
`systemd.services.greetd.environment.DMS_GREET_REMEMBER_LAST_SESSION = "false"`,
so the greeter never persists a session pick and always lands on the
first-listed (UWSM) session. The env override is read before settings.json
(`GreetdSettings.qml`); greetd forwards it to the greeter the same way it
forwards `TZDIR`/`LOCALE_ARCHIVE`. Last-USER memory
(`DMS_GREET_REMEMBER_LAST_USER`) is a separate flag and stays on.

### Diagnostic signature

Confirm the session is the non-UWSM one (all four hold together):

```sh
systemctl --user is-active graphical-session.target     # → inactive
systemctl --user is-active wayland-wm@hyprland.desktop.service   # → inactive
ps -o ppid=,comm= -p "$(pgrep -x Hyprland)"             # parent is greetd, not a systemd scope
loginctl show-session "$XDG_SESSION_ID" -p Type -p Desktop   # Type=unspecified, Desktop= (empty)
```

A healthy UWSM session has `graphical-session.target` **active**,
`wayland-wm@hyprland.desktop.service` **active**, and `UWSM_*` variables in the
compositor's environment.

> Do not judge UWSM by `env` in a random terminal — an SSH/`pts` shell is a
> *different* login session and never carries the compositor's UWSM env. Read the
> unit states (shared user manager) or the compositor's own `/proc/<pid>/environ`.

### Recovery

- **Permanent / cleanest:** at the greeter, pick **"Hyprland (uwsm-managed)"**
  once. It re-saves the UWSM pin and self-heals future logins. (Equivalent:
  delete `/var/lib/dms-greeter/.local/state/memory.json`.)
- **Live, no relog:** the user manager already imported `WAYLAND_DISPLAY`, so the
  cluster can be started by hand —
  `systemctl --user start dms hyprpaper hyprpolkitagent snappy-switcher voxtype wl-clip-persist`.
  This does *not* activate `graphical-session.target` (only UWSM does), but it
  brings the shell back for the current session.
- **Permanent (wired in):** `DMS_GREET_REMEMBER_LAST_SESSION = "false"` on the
  greetd service (see "Hardening" above) makes the pin impossible — the greeter
  always defaults to the UWSM session. Note `--remember-last-session` is *not* a
  greeter CLI flag; the supported levers are this env var or the
  `greeterRememberLastSession` key in the greeter's `settings.json`.

## See also

- `modules/desktop/hyprland/default.nix` — the `withUWSM = true` block, with the
  inline rationale this doc expands on.
- `lib/systemd-helpers.nix` — `mkGraphicalUserService`, the
  `graphical-session.target` binding shared by every per-session service.
- `docs/workarounds.md` — the `hyprpolkitagent` `ConditionGroup=!greeter` guard,
  a related greeter-vs-session interaction.
