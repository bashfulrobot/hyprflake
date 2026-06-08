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

| Option                          | Type   | Default | Description                                       |
| ------------------------------- | ------ | ------- | ------------------------------------------------- |
| `desktop.displayManager.enable` | `bool` | `true`  | Configure the DankGreeter (greetd) login manager  |

The login manager is DankMaterialShell's greetd-based greeter (DankGreeter).
GDM was removed in favour of it, so the login screen and the shell share one
Stylix-controlled theme via the greeter's `configHome` copy (no matugen), and
the GDM 50 / gnome-session workaround stack is gone. Set `enable = false` to
run your own login manager instead. There is no in-tree GDM fallback; roll back
with the `backup/pre-dank-baseline` branch or a previous NixOS generation.

`hyprflake.user.username` must be set (and that user declared in `users.users`)
so the greeter can read the user's home for `configHome`.

The greeter theme is copied from the user's exported DMS state
(`settings.json`, `dms-colors.json`), which only exists after the user has run
DMS at least once. On a fresh machine before the first DMS launch, the login
screen falls back to the default DMS theme. It is unthemed, not broken. The
config is read from the user's declared home (`users.users.<name>.home`), so
impermanence and home overrides resolve correctly.

Keyring auto-unlock: the `pam_gnome_keyring` hook is on the `greetd` PAM service
(see `modules/system/keyring`), plus `login` for the DMS lock-screen re-unlock.
Auto-unlock without a second prompt needs the login password to equal the
login-keyring password. The keyring stack itself (gnome-keyring + gcr-ssh-agent)
is unchanged.

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

### Idle (lock / screen-off / suspend)

Consumed by DMS's idle daemon. Each value is in seconds; `0` disables that step.
DMS locks before suspend and honors `loginctl lock-session`.

| Option                      | Type  | Default | Description                                                              |
| --------------------------- | ----- | ------- | ------------------------------------------------------------------------ |
| `desktop.idle.lockTimeout`  | `int` | `300`   | Seconds idle before locking the session. `0` disables.                   |
| `desktop.idle.dpmsTimeout`  | `int` | `360`   | Seconds idle before turning displays off (DPMS). `0` keeps the screen on. |
| `desktop.idle.suspendTimeout` | `int` | `600`  | Seconds idle before suspend. `0` disables.                               |

### Update checks

A systemd user timer that surfaces, on the workstation, when a newer
DankMaterialShell, Hyprland, dms-emoji-launcher, or Voxtype is available. DMS
is pinned to a master commit until a release carries the Lua-config dispatch
fix (see `docs/workarounds.md`); this flags when that release lands, when
Hyprland moves upstream of the nixpkgs build, when the emoji-launcher pin has a
newer commit, and when Voxtype tags a new release. It polls GitHub's public
API, sends a DMS notification, and prints a one-line notice in interactive fish
sessions. The on-demand command is `hyprflake-updates`; the flake-repo analog
is `just dms-check`.

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
