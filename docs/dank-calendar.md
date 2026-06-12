# Google Calendar in DankDash

How `hyprflake.desktop.dank.calendar` wires Google Calendar into DMS's DankDash
via `vdirsyncer` (CalDAV sync) and `khal` (the store DMS reads).

## How it fits together

DMS reads calendar events from `khal` automatically — the DMS home module's
`enableCalendarEvents` defaults to `true`, so no DMS setting is involved. The
missing pieces are a synced calendar and a `khal` that can see it. This module
supplies them:

1. **vdirsyncer** pulls Google Calendar over CalDAV into local `.ics` files
   under `$XDG_DATA_HOME/vdirsyncer/calendars/`.
2. **khal** is pointed at that directory (`type = discover`), so it surfaces
   every synced calendar.
3. A **systemd user timer** re-syncs on `calendar.syncInterval` (default 15m).

`vdirsyncer` in nixpkgs already ships `aiohttp-oauthlib`, so its
`google_calendar` storage works with no package override.

> Upstream documents this khal/vdirsyncer path as convoluted and plans to
> replace it with a native **DankCalendar**
> (<https://danklinux.com/docs/dankmaterialshell/calendar-integration>). When
> that lands, prefer it and retire this module.

## One-time Google setup (manual)

This is the part that cannot be declarative — it needs a Google account and a
browser OAuth grant.

1. **Create OAuth credentials** in the [Google Cloud Console](https://console.cloud.google.com/):
   - Create (or pick) a project and **enable the Google Calendar API**.
   - APIs & Services → Credentials → **Create credentials → OAuth client ID →
     Desktop app**.
   - Note the **client ID** and **client secret**.
2. **Store the secret out of the Nix store.** Put the client secret in a file
   your consumer can reference — a sops-nix / agenix secret, or any
   root-or-user-readable path. hyprflake reads it at home-manager activation and
   writes it into `~/.config/vdirsyncer/config` with mode `0600`; it is never
   copied into the world-readable store.

## Consumer configuration (nixerator)

```nix
hyprflake.desktop.dank.calendar = {
  enable = true;
  clientId = "1234567890-abcdefg.apps.googleusercontent.com";
  # Absolute path to a file containing ONLY the client secret.
  clientSecretFile = config.sops.secrets."google-calendar-client-secret".path;
  # syncInterval = "30m";  # optional, default "15m"
};
```

`clientId` and `clientSecretFile` are mandatory when `enable = true` (asserted at
build). `clientSecretFile` must be an absolute path.

## First sync (manual, once)

After the first rebuild that enables this, run the interactive discovery so
vdirsyncer can complete the OAuth grant and learn your calendars:

```sh
vdirsyncer discover google
```

This opens a browser, you approve access, and vdirsyncer writes the OAuth token
to `$XDG_DATA_HOME/vdirsyncer/google_calendar_token`. Then prime the first sync:

```sh
vdirsyncer sync
```

The timer takes over from there. Until `discover` has run, the
`vdirsyncer.service` oneshot fails on each tick (harmless, just logged).

## Verify

```sh
khal list today 7d          # should print upcoming events
systemctl --user status vdirsyncer.timer
```

Then open DankDash (`SUPER+D`) — the overview's calendar card shows the events.

## Notes

- The vdirsyncer config is written at activation, not as a store symlink,
  precisely so the client secret stays out of the store. The non-secret `khal`
  config is a normal store symlink.
- Syncing is read-oriented (`conflict_resolution = "b wins"`, with Google as
  `b`); this module is for *showing* events in DankDash, not editing them.
- `metadata = ["color", "displayname"]` carries each calendar's colour and name
  through to khal/DMS.
