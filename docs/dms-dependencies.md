# DMS Runtime Dependencies

The external tools and system services DankMaterialShell shells out to at
runtime, which of them hyprflake must supply itself, and which are covered
elsewhere or deliberately left out. Read this when a DMS feature silently no-ops
(the surface goes inert, nothing is logged) or when auditing dependencies after a
`dank-material-shell` bump.

**Revisit on every `dank-material-shell` input bump.** New features add new
`command -v` probes and `exec` calls, and upstream's `nixos.nix` service list can
grow. Re-run the audit below.

## Why hyprflake carries these at all

hyprflake wires DMS through two upstream modules and skips a third:

- `homeModules.dank-material-shell` — the shell, its plugins, and settings.
- `nixosModules.greeter` — the DankGreeter login surface.
- **not** `nixosModules.dank-material-shell` (`distro/nix/nixos.nix`), the shell's
  main NixOS module.

The home module pulls in DMS's runtime *packages* through `common.packages`
(`distro/nix/common.nix`), gated on the feature toggles: `dgop` with
`enableSystemMonitoring`, `glib` + `networkmanager` with `enableVPN` (default
true), `matugen` with `enableDynamicTheming`, `cava` with `enableAudioWavelength`,
`khal` with `enableCalendarEvents`. So package deps track their feature and need
no restating.

What a home-manager module cannot do is set system services. `nixos.nix` sets
four of them `mkDefault true`, and since hyprflake never imports it, any service
DMS needs has to be restated on hyprflake's side, or the dependent feature
quietly no-ops. This is the same failure mode as a missing CLI tool on `PATH`.

## What hyprflake supplies

Tools and services DMS needs that hyprflake provides directly, because nothing
upstream in its wiring does:

| Dependency | Where | Feature |
| --- | --- | --- |
| `pactl` (pulseaudio) | `dank` module `home.packages` | Bluetooth codec switching (`pactl set-card-profile`); pulseaudio ships `pactl`, PipeWire does not |
| `services.accounts-daemon` | `dank` module | Control-center user avatar (`org.freedesktop.Accounts` get/set) + greeter icon cache |
| `services.geoclue2` | `dank` module | Night-mode sunrise/sunset auto-location + weather |

The two services mirror `nixos.nix`. The other two services that module sets are
already covered outside the `dank` module (next section), so they are not
restated there.

## Covered elsewhere (do not duplicate)

| Dependency | Provided by |
| --- | --- |
| `security.polkit.enable` | `modules/desktop/hyprland` |
| `services.power-profiles-daemon` | `modules/system/power`, the DMS battery-widget profile control (laptop default; TLP disabled as mutually exclusive) |
| `wpctl` (core volume/mute path) | NixOS wireplumber module adds it to `systemPackages` |
| `gsettings`/`glib`, `nmcli` client | DMS `home.packages` via `common.packages` (`enableVPN` default true) |
| `dgop`, `dsearch`, `khal`, `qtmultimedia`, `libnotify`, `cliphist`, `dconf`, `hyprctl`, `uwsm` | respective modules / `common.packages` |

## Deliberately absent

| Dependency | Reason |
| --- | --- |
| `matugen` | `enableDynamicTheming = false`; Stylix owns theming |
| `cava` | `enableAudioWavelength` off; the audio visualizer is not enabled |
| `fprintd` | fingerprint unlock is hardware- and policy-conditional; the consumer enables `services.fprintd` |
| U2F/FIDO2 lockscreen | opt-in `lockscreen.securityKey` in upstream `nixos.nix`, not wired |
| NetworkManager *daemon* | the `nmcli` client is on `PATH`, but enabling the daemon is the consumer's networking policy (it can conflict); hyprflake makes no hard runtime assumption |

## Auditing after a bump

The dependency set lives in the DMS source tree, not in one manifest. Upstream's
own packaging `Requires`/`Recommends` miss the graceful-degradation probes: it
never listed `pactl`. To re-audit, resolve the input's store path and grep it:

```
p=$(nix eval --raw --impure \
  --expr '(builtins.getFlake (toString ./.)).inputs.dank-material-shell.outPath')

# optional/probed tools (degrade gracefully)
grep -rhoE 'command -v [a-zA-Z0-9_-]+' "$p/quickshell" | sort -u

# directly invoked binaries (QML)
grep -rhoE 'command:\s*\[\s*"[a-zA-Z0-9_./-]+"' "$p/quickshell" \
  | grep -oE '"[a-zA-Z0-9_./-]+"$' | tr -d '"' | sort -u
grep -rhoE 'execDetached\(\s*\[\s*"[a-zA-Z0-9_./-]+"' "$p/quickshell" \
  | grep -oE '"[a-zA-Z0-9_./-]+"$' | tr -d '"' | sort -u

# system services upstream expects
grep -n 'services\.\|security\.' "$p/distro/nix/nixos.nix"

# runtime package list (per feature toggle)
cat "$p/distro/nix/common.nix"
```

Separate genuine runtime deps from the `dms` CLI's cross-distro installer tooling
(git, cargo, cmake, pacman, apt, flatpak, distro package managers) in `core/`;
those install and build paths never run on NixOS. Then cross-reference the
survivors against the tables above.
