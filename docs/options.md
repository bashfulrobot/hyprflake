# Hyprflake Configuration Options

Complete reference for all hyprflake configuration options, organized into logical groups.

## Table of Contents

- [Style Configuration](#style-configuration)
- [User Configuration](#user-configuration)
- [Desktop Configuration](#desktop-configuration)
- [System Configuration](#system-configuration)
- [Configuration Examples](#configuration-examples)

## Style Configuration

Visual appearance and theming options for your Hyprland desktop.

### Color & Theming

| Option              | Type                                | Default                          | Description                                                                                                                        |
| ------------------- | ----------------------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `style.colorScheme` | `string`                            | `"catppuccin-mocha"`             | Base16 color scheme from pkgs.base16-schemes. Browse schemes at [base16-gallery](https://tinted-theming.github.io/base16-gallery/) |
| `style.wallpaper`   | `path`                              | `../wallpapers/galaxy-waves.jpg` | Path to wallpaper image file                                                                                                       |
| `style.polarity`    | `"dark"` \| `"light"` \| `"either"` | `"dark"`                         | Theme polarity preference                                                                                                          |

### Fonts

| Option                          | Type      | Default                       | Description                                |
| ------------------------------- | --------- | ----------------------------- | ------------------------------------------ |
| `style.fonts.monospace.name`    | `string`  | `"Iosevka Nerd Font"`         | Monospace font name for terminals and code |
| `style.fonts.monospace.package` | `package` | `pkgs.nerd-fonts.iosevka`     | Monospace font package                     |
| `style.fonts.sansSerif.name`    | `string`  | `"Inter"`                     | Sans-serif font name for UI elements       |
| `style.fonts.sansSerif.package` | `package` | `pkgs.inter`                  | Sans-serif font package                    |
| `style.fonts.serif.name`        | `string`  | `"Noto Serif"`                | Serif font name for documents              |
| `style.fonts.serif.package`     | `package` | `pkgs.noto-fonts`             | Serif font package                         |
| `style.fonts.emoji.name`        | `string`  | `"Noto Color Emoji"`          | Emoji font name                            |
| `style.fonts.emoji.package`     | `package` | `pkgs.noto-fonts-color-emoji` | Emoji font package                         |

### Cursor

| Option                 | Type      | Default                             | Description                                |
| ---------------------- | --------- | ----------------------------------- | ------------------------------------------ |
| `style.cursor.name`    | `string`  | `"catppuccin-mocha-dark-cursors"`   | Cursor theme name                          |
| `style.cursor.size`    | `int`     | `24`                                | Cursor size in pixels (common: 24, 32, 48) |
| `style.cursor.package` | `package` | `pkgs.catppuccin-cursors.mochaDark` | Cursor theme package                       |

### Icon Theme

| Option               | Type      | Default                   | Description        |
| -------------------- | --------- | ------------------------- | ------------------ |
| `style.icon.name`    | `string`  | `"Papirus-Dark"`          | Icon theme name    |
| `style.icon.package` | `package` | `pkgs.papirus-icon-theme` | Icon theme package |

### Opacity

Window opacity settings (0.0 = transparent, 1.0 = opaque).

| Option                       | Type    | Default | Description                |
| ---------------------------- | ------- | ------- | -------------------------- |
| `style.opacity.terminal`     | `float` | `0.9`   | Terminal window opacity    |
| `style.opacity.desktop`      | `float` | `1.0`   | Desktop background opacity |
| `style.opacity.popups`       | `float` | `0.95`  | Popup window opacity       |
| `style.opacity.applications` | `float` | `1.0`   | Application window opacity |

## User Configuration

User profile settings.

| Option          | Type            | Default | Description                                                                                                |
| --------------- | --------------- | ------- | ---------------------------------------------------------------------------------------------------------- |
| `user.username` | `nullOr string` | `null`  | **Optional but recommended.** Username for user-specific configurations. Required if setting `user.photo`. |
| `user.photo`    | `nullOr path`   | `null`  | Path to user profile photo (96x96+ recommended, JPG/PNG). Requires `user.username` to be set.              |

**Note:** While these options have default values of `null`, it's recommended to set `user.username` for proper user-specific configurations. The `user.photo` option requires `user.username` to be set.

## Desktop Configuration

Desktop environment behavior and input settings.

### Keyboard

| Option                     | Type     | Default | Description                                       |
| -------------------------- | -------- | ------- | ------------------------------------------------- |
| `desktop.keyboard.layout`  | `string` | `"us"`  | Keyboard layout (can be comma-separated: "us,de") |
| `desktop.keyboard.variant` | `string` | `""`    | Keyboard variant (e.g., "colemak", "dvorak")      |

### Display Manager

The login manager is DankMaterialShell's greetd-based greeter (DankGreeter).
It is core infrastructure with no enable option, the same as the DMS shell:
always present, always the login path. GDM was removed in favour of it, so the
login screen and the shell share one Stylix-controlled theme via the greeter's
`configHome` copy (no matugen), and the GDM 50 / gnome-session workaround stack
is gone. To run a different login manager, override `services.greetd` or
`programs.dank-material-shell.greeter` directly. There is no in-tree GDM
fallback; roll back with the `backup/pre-dank-baseline` branch or a previous
NixOS generation.

Set `hyprflake.user.username` (and declare that user in `users.users`) so the
greeter can read the user's home for `configHome` theming and resolve the login
avatar. Without it the greeter still logs you in, just with the default theme
and no avatar, and the build emits a warning saying so. The keyboard layout
from `hyprflake.desktop.keyboard` is propagated to the greeter automatically.

To set the login avatar, point `hyprflake.user.photo` at an image. The
`system/user` module copies it to `/var/lib/AccountsService/icons/<username>`,
which is one of the paths the greeter probes for each user's face (after its own
`dms greeter sync` cache, before `~/.face`). No imperative `dms greeter sync`
step is needed; the AccountsService path is declarative and NixOS-native.

The greeter theme is copied from the user's exported DMS state
(`settings.json`, `dms-colors.json`), which only exists after the user has run
DMS at least once. On a fresh machine before the first DMS launch, the login
screen falls back to the default DMS theme. It is unthemed, not broken. The
config is read from the user's declared home (`users.users.<name>.home`), so
impermanence and home overrides resolve correctly.

**The DMS Settings → Greeter Status panel shows false negatives here.** That
panel runs `dms greeter status`, which only recognises the *imperative* install
(`dms greeter install` / `dms greeter sync`): a `dms-greeter` package marker, a
`greeter` group the primary user belongs to, and ACLs on the user's home so the
greeter can read it live. hyprflake configures the greeter the NixOS-native way
instead — `programs.dank-material-shell.greeter` builds the greetd config and
the theme is a snapshot copied into `/var/lib/dms-greeter` at greetd preStart —
so the check reports "greeter config not found" and "user is NOT in greeter
group" even though the greeter is installed, themed, and working. Ignore it, and
do **not** click the panel's **Sync** / **Install** buttons (or run `dms greeter
sync` / `dms greeter install`): they write a competing greetd config and ACLs
that conflict with the declarative setup. Adding the primary user to the
`greeter` group is cosmetic only — the greeter reads its own snapshot, never
your home, so the group grants access it never uses. It silences the panel's
group line, but "config not found" persists because no imperative install
marker exists.

Keyring auto-unlock: the `pam_gnome_keyring` hook is on the `greetd` PAM service
(see `modules/system/keyring`), plus `login` for the DMS lock-screen re-unlock.
The `greetd` hook is attached whenever `services.greetd.enable` is true, which
hyprflake always sets via the greeter, so it tracks the service rather than being
forced on. Auto-unlock without a second prompt needs the login password to equal
the login-keyring password. The keyring stack itself (gnome-keyring +
gcr-ssh-agent) is unchanged.

Security note: the greeter's root `preStart` copies file paths referenced in
your DMS `settings.json` / `session.json` (theme file, wallpapers) into
`/var/lib/dms-greeter` and makes them readable by the unprivileged `greeter`
user. Any path placed in those files is followed by root, so do not point DMS
theme or wallpaper settings at secrets. This is upstream greeter behavior,
tracked in `docs/workarounds.md`.

### Desktop Shell (DankMaterialShell)

The desktop shell is [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
(DMS): one Quickshell process providing the bar, launcher, notifications, OSD,
power menu, lock screen, and idle daemon. It is hyprflake's core shell and is
always enabled — there is no toggle (one would only be needed to support
multiple shells). It replaces the old waybar stack.

### Frosted-glass look

| Option                            | Type   | Default | Description                                                              |
| --------------------------------- | ------ | ------- | ------------------------------------------------------------------------ |
| `desktop.dank.frostedGlass.enable` | `bool` | `false` | Frost the `dms:*` surfaces with Hyprland layer-shell blur + DMS panel blur |

Off by default, which keeps the current flat, truly-transparent look. One switch
drives both halves of the effect: DMS's own panel/overview blur (`blurEnabled`,
`blurWallpaperOnOverview`) and the Hyprland `hl.layer_rule` blur + slide
animations for the windows behind each `dms:*` layer (bar, popouts, modals,
overview). Hyprland has no `ext-bg-effect-v1`, so layer blur is opt-in per
namespace — see `docs/styling.md` and
[the DMS layers docs](https://danklinux.com/docs/dankmaterialshell/layers).

### DMS Settings Capture

By default, `hyprflake.desktop.dank.settings` renders to a read-only
`~/.config/DankMaterialShell/settings.json` symlink into the Nix store. The DMS
GUI shows a "read-only" banner and any changes made there do not persist across
reboot or rebuild.

Enabling capture flips the GUI into the editing surface and round-trips changes
back into your consumer repo. When `capture.enable = true`, the symlink is
replaced by a writable file managed by the capture scripts; the "read-only"
banner disappears and GUI edits survive reboots.

```nix
hyprflake.desktop.dank.capture = {
  enable = true;
  # Group identity: hosts sharing a group name share one overrides file.
  # Defaults to the hostname (each host isolated). Set the same value on
  # several hosts to share a profile, or a custom name like "laptops".
  group = "workstations";
  repoRoot = "/home/<you>/git/<repo>/dank-profiles";   # worktree dir (writes)
  overridesDir = ./dank-profiles;                       # Nix path (reads)
};
```

dank-capture reads and writes `<repoRoot>/<group>.json`. `repoRoot` is the live
working-tree directory it writes to; `overridesDir` is a Nix path to the same
directory used to import the active group's overrides at eval time (the
`<group>.json` file must be git-tracked to be visible to the flake).

An absolute write path is required when `capture.enable = true` and is enforced
by a module assertion — provide it via `repoRoot` (recommended) or by setting
`repoPath` directly. The low-level `repoPath` (write path) and `overrides`
(parsed delta) options remain available and default to the group-derived values;
set them directly only to bypass the group/`repoRoot` convention.

**Grouping:** the `group` string subsumes shared, per-host, and arbitrary-subset
layouts. Same name on N hosts → those hosts share a profile; `group` left at the
default hostname → per-host isolation; a custom name like `"laptops"` → a subset
group. Because capture writes the full settings file (not a cross-host merge), a
shared group is last-write-wins: tweak on one host, capture, then rebuild the
others.

**Full-file model:** capture writes your *complete* live settings (not a minimal
delta) into `<group>.json`, with the stylix-managed theme keys stripped. Writing
the full file means DMS finds every key already present on launch and never
re-materialises its ~450-key default schema, so the on-disk file stays stable.
Stripping the theme keys (`currentThemeName`, `fontFamily`, `monoFontFamily`,
`customThemeFile`, `dockTransparency`, `popupTransparency`) keeps theming
declarative — it always tracks stylix — and keeps the profile portable across
hosts (no baked-in `/nix/store` theme paths).

**Capture workflow:**

1. Edit settings in the DMS GUI — changes are now writable and persist across
   reboots.
2. Run `dank-capture` — writes your full theme-stripped live `settings.json` into
   `<group>.json` at `repoRoot`.
3. Commit `<group>.json` and rebuild. On activation the seed installs
   `merge(hyprflake defaults + stylix theme, your captured profile)`, so the
   theme is re-applied from Nix while your captured settings win. Precedence:
   hyprflake default → consumer Nix (`settings.*`) → GUI-captured
   (`capture.overrides`), last wins.

Two helper commands complement the workflow. `dank-diff` is a dry-run that prints
what `dank-capture` would write (your theme-stripped live settings) without
touching the profile. `dank-discard` drops any un-captured GUI edits and resets
`settings.json` to the seeded config (defaults + stylix theme + captured profile).

**Clobber-guard:** a rebuild attempted while you have un-captured GUI edits is
refused with a warning rather than silently overwriting them. Run `dank-capture`
to commit the edits or `dank-discard` to drop them before rebuilding. The guard
compares settings numerically, so the int-vs-float spelling DMS and Nix use for
whole-number values (e.g. `dockTransparency` `1` vs `1.0`) is never mistaken for
an edit.

**List fields and `lib.mkForce`:** any list field (such as `barConfigs`) that
you override purely through the Nix `settings.*` options requires `lib.mkForce`,
because Nix lists do not deep-merge and the module system will otherwise reject
the conflict. The GUI and capture path replace lists wholesale automatically, so
`lib.mkForce` is only needed on the Nix side.

**Scope:** only `settings.json` is managed this way. `session.json` is already
writable by DMS and is left untouched. `plugin_settings.json` stays fully
declarative with no capture path.

### Launcher file search (DankSearch)

| Option                  | Type   | Default | Description                                          |
| ----------------------- | ------ | ------- | ---------------------------------------------------- |
| `desktop.search.enable` | `bool` | `true`  | Run DankSearch (dsearch) as the DMS launcher backend |

The DMS launcher's file search auto-detects `dsearch` (`command -v dsearch`)
and otherwise prints "File search requires dsearch". Enabling this runs
`dsearch serve` as a user service and puts the binary on PATH; DMS then uses it,
no DMS setting required. The index lives under `XDG_CACHE_HOME/danksearch`, not
the store. Unlike the shell it has a toggle, because it is a background daemon
that walks the home tree (depth 6) and holds an fsnotify watch per directory, so
on a very large home it can press against `fs.inotify.max_user_watches` and
carries a standing CPU/disk/battery cost. Set it to `false` to fall back to the
launcher's built-in path walk.

The daemon runs socket-only (`dsearch serve --socket`), so the unauthenticated
HTTP API it otherwise opens on `127.0.0.1:43654` is off; DMS talks to it over a
per-user unix socket. The index directory is forced to owner-only (0700).
Dotfiles and dotdirs are skipped (`exclude_hidden`), so `~/.ssh`, `~/.config`,
and `~/.aws` are not indexed, but every other filename under the home tree is,
and the contents of non-hidden text files are read for full-text search. A
non-hidden file that holds a secret (a `secrets.nix`, a token in a `*.json` or
`*.toml`, a credential in a `*.yml`) therefore lands in the index. The index is
readable only by you, the same as the files it mirrors, but it does aggregate
that content in one place, so keep real secrets in dotdirs or outside the home
tree.

### Google Calendar in DankDash

| Option                                 | Type             | Default | Description                                                      |
| -------------------------------------- | ---------------- | ------- | ---------------------------------------------------------------- |
| `desktop.dank.calendar.enable`         | `bool`           | `false` | Sync Google Calendar to khal so DankDash shows events           |
| `desktop.dank.calendar.clientId`       | `string`         | `""`    | Google OAuth Desktop-app client ID                              |
| `desktop.dank.calendar.clientSecretFile` | `null \| string` | `null`  | Absolute path to a file holding the OAuth client secret         |
| `desktop.dank.calendar.syncInterval`   | `string`         | `"15m"` | systemd `OnUnitActiveSec` for the periodic sync timer           |

DMS reads khal events automatically (`enableCalendarEvents`, default on). This
module adds `vdirsyncer` + `khal`, writes their configs, and syncs Google over
CalDAV on a timer. The client secret is injected at activation and never enters
the Nix store. A one-time interactive `vdirsyncer discover` (browser OAuth) is
required — see `docs/dank-calendar.md` for the full setup.

### Idle (lock / screen-off / suspend)

Consumed by DMS's idle daemon. Each value is in seconds; `0` disables that step.
DMS locks before suspend and honors `loginctl lock-session`.

The three base options feed DMS's AC timeouts. The three `battery*` options feed
DMS's battery timeouts; each defaults to `null`, which tracks its AC counterpart,
so a config that sets only the base options produces the same six DMS values it
did before (battery equals AC). An explicit `0` on a battery option disables that
step on battery, so `0` and `null` differ: `0` is off, `null` is "same as AC".

| Option                      | Type  | Default | Description                                                              |
| --------------------------- | ----- | ------- | ------------------------------------------------------------------------ |
| `desktop.idle.lockTimeout`  | `int ≥ 0` | `300`   | Seconds idle before locking the session (AC). `0` disables.             |
| `desktop.idle.dpmsTimeout`  | `int ≥ 0` | `360`   | Seconds idle before turning displays off (DPMS, AC). `0` keeps the screen on. |
| `desktop.idle.suspendTimeout` | `int ≥ 0` | `600`  | Seconds idle before suspend (AC). `0` disables.                          |
| `desktop.idle.batteryLockTimeout` | `null` or `int ≥ 0` | `null` | Lock timeout on battery. `null` tracks `lockTimeout`; `0` disables locking on battery. |
| `desktop.idle.batteryDpmsTimeout` | `null` or `int ≥ 0` | `null` | Display-off (DPMS) timeout on battery. `null` tracks `dpmsTimeout`; `0` keeps the screen on. |
| `desktop.idle.batterySuspendTimeout` | `null` or `int ≥ 0` | `null` | Suspend timeout on battery. `null` tracks `suspendTimeout`; `0` disables suspend on battery. |

### Update checks

A systemd user timer that surfaces, on the workstation, when a newer
DankMaterialShell, Hyprland, dms-emoji-launcher, or Voxtype is available. It
flags when a pinned input has a newer upstream release/commit, when Hyprland
moves upstream of the nixpkgs build, when the emoji-launcher pin has a newer
commit, and when Voxtype tags a new release. It polls GitHub's public API,
sends a DMS notification, and prints a one-line notice in interactive fish
sessions. The on-demand command is `hyprflake-updates`.

| Option                          | Type   | Default   | Description                                                       |
| ------------------------------- | ------ | --------- | ----------------------------------------------------------------- |
| `desktop.updateChecks.enable`   | `bool` | `true`    | Enable the periodic DMS / Hyprland update check.                  |
| `desktop.updateChecks.notify`   | `bool` | `true`    | Send a DMS desktop notification when updates are found.           |
| `desktop.updateChecks.shellNotice` | `bool` | `true` | Print a one-line notice in interactive fish sessions.             |
| `desktop.updateChecks.onCalendar` | `str` | `"daily"` | `systemd` `OnCalendar` expression for the check cadence.          |

### Voxtype

Push-to-talk voice-to-text options (Whisper).

| Option                    | Type         | Default                                                   | Description                                                                                            |
| ------------------------- | ------------ | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `desktop.voxtype.enable`  | `bool`       | `false`                                                   | Enable Voxtype push-to-talk voice-to-text                                                              |
| `desktop.voxtype.package` | `package`    | `hyprflakeInputs.voxtype.packages.${pkgs.system}.default` | Voxtype package to use                                                                                 |
| `desktop.voxtype.hotkey`  | `string`     | `"SCROLLLOCK"`                                            | Evdev key name for push-to-talk activation (hold to record, release to transcribe)                     |
| `desktop.voxtype.model`   | `string`     | `"base.en"`                                               | Whisper model name (e.g., `tiny.en`, `base.en`, `small.en`, `medium.en`, `large-v3`, `large-v3-turbo`) |
| `desktop.voxtype.threads` | `nullOr int` | `null`                                                    | Number of CPU threads for Whisper inference. When null, voxtype auto-detects.                          |

### Snappy Switcher

Traditional MRU Alt+Tab window switcher for Hyprland. DMS's `SUPER+Tab`
overview is a spatial exposé, not a switcher, so this fills the alt-tab gap
(see `docs/architecture.md`).

This is core desktop function: it is always on and exposes **no options**. It
owns `ALT+Tab` / `ALT+SHIFT+Tab` (the hyprland module binds no native
`cycle_next` fallback on those keys), shows one card per window with the app
icon and window title (no badges), and derives all colors from the active
Stylix palette.

## System Configuration

System-level settings.

| Option                   | Type   | Default | Description                                                                                                                            |
| ------------------------ | ------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `system.isLaptop`        | `bool` | `false` | Mark host as a laptop: enables UPower for battery monitoring, shows the DMS battery / power-profile bar widget, and defaults `power.profilesBackend` to `power-profiles-daemon`. Leave off on desktops. |
| `system.plymouth.enable` | `bool` | `false` | Enable Plymouth boot splash (auto-detects Catppuccin themes)                                                                          |

## Configuration Examples

### Minimal Configuration (Using Defaults)

The simplest configuration uses all defaults and only specifies user information:

```nix
{
  hyprflake.user = {
    username = "dustin";
    photo = ./my-photo.jpg;
  };
}
```

This gives you:

- Catppuccin Mocha color scheme
- Default galaxy-waves wallpaper
- Iosevka Nerd Font for terminals
- Inter font for UI
- Dark theme
- All other defaults

### Customizing Selected Options

Here's an example showing how to override specific options while keeping other defaults:

```nix
{
  hyprflake = {
    # Customize visual style
    style = {
      colorScheme = "gruvbox-dark-hard";
      wallpaper = ./wallpapers/my-wallpaper.png;

      # Use JetBrains Mono instead of default Iosevka
      fonts.monospace = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };

      # Larger cursor for HiDPI displays
      cursor.size = 32;

      # More transparent terminal
      opacity.terminal = 0.85;
    };

    # User profile
    user = {
      username = "dustin";
      photo = ./my-photo.jpg;
    };

    # Enable Plymouth boot splash
    system.plymouth.enable = true;
  };
}
```

### Overriding in Host Configuration

You can override any hyprflake setting in your host-specific configuration:

```nix
# In your host configuration.nix
{
  # Override just the wallpaper for this host
  hyprflake.style.wallpaper = ./host-specific-wallpaper.png;

  # Override keyboard layout for this host
  hyprflake.desktop.keyboard = {
    layout = "us,de";
    variant = "colemak";
  };
}
```

### Enabling Voxtype (Push-to-Talk)

Example enabling Voxtype with a custom hotkey and model:

```nix
{
  hyprflake.desktop.voxtype = {
    enable = true;
    hotkey = "F13";
    model = "small.en";
    threads = 4;  # Limit to 4 CPU threads (omit to let voxtype auto-detect)
  };
}
```

## Notes

### Mandatory vs Optional

- **All options are technically optional** and have sensible defaults
- **Recommended minimum**: Set `user.username` for proper user-specific configurations
- **User Photo**: If you want to use `user.photo`, you must also set `user.username`

### Integration Details

- **Stylix Integration**: Most style options are passed to Stylix, which handles system-wide theming
- **Font Packages**: When changing fonts, both `name` and `package` must match
- **Multiple Keyboards**: Use comma-separated layouts: `"us,de"`
- **Opacity Values**: Range from 0.0 (transparent) to 1.0 (opaque)
