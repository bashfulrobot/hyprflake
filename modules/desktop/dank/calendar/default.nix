{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.dank.calendar;
  inherit (lib) mkOption mkEnableOption types mkIf;
in
{
  # Google Calendar events in DankDash. DMS reads khal events automatically
  # (programs.dank-material-shell.enableCalendarEvents, default true), so this
  # module only has to (1) put vdirsyncer + khal on PATH, (2) write their
  # configs, and (3) sync on a timer. nixpkgs' vdirsyncer already ships
  # aiohttp-oauthlib, so the `google_calendar` storage works with no override.
  #
  # Upstream's own calendar path is khal/vdirsyncer and is documented as
  # convoluted (danklinux.com/docs/dankmaterialshell/calendar-integration); a
  # future DankCalendar is planned to replace it. This module makes the
  # declarative parts first-class and keeps the OAuth client secret out of the
  # Nix store; the one-time interactive token grant stays a manual step. See
  # docs/dank-calendar.md for the full setup, including `vdirsyncer discover`.
  options.hyprflake.desktop.dank.calendar = {
    enable = mkEnableOption "Google Calendar events in DankDash (vdirsyncer + khal CalDAV sync)";

    clientId = mkOption {
      type = types.str;
      default = "";
      example = "1234567890-abcdefg.apps.googleusercontent.com";
      description = ''
        Google OAuth 2.0 *Desktop app* client ID. Create it in the Google Cloud
        Console: enable the Google Calendar API, then APIs & Services →
        Credentials → Create credentials → OAuth client ID → Desktop app. The
        client ID is not sensitive on its own; the matching secret goes in
        {option}`clientSecretFile`. Required when {option}`enable` is true.
      '';
    };

    clientSecretFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/run/secrets/google-calendar-client-secret";
      description = ''
        Absolute path to a file containing ONLY the Google OAuth client secret.
        It is read at home-manager activation and appended to
        `$XDG_CONFIG_HOME/vdirsyncer/config` with mode 0600 — it is never copied
        into the world-readable Nix store. Provide it from your consumer's secret
        manager (sops-nix / agenix) or any other out-of-store path. Required when
        {option}`enable` is true.
      '';
    };

    syncInterval = mkOption {
      type = types.str;
      default = "15m";
      example = "30m";
      description = ''
        systemd `OnUnitActiveSec` value for the periodic vdirsyncer sync timer.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.clientId != "";
        message = "hyprflake.desktop.dank.calendar.enable requires clientId (the Google OAuth Desktop-app client ID).";
      }
      {
        assertion = cfg.clientSecretFile != null && lib.hasPrefix "/" cfg.clientSecretFile;
        message = "hyprflake.desktop.dank.calendar.enable requires clientSecretFile to be an ABSOLUTE path to the OAuth client secret.";
      }
    ];

    home-manager.sharedModules = [
      ({ config, pkgs, lib, ... }:
        let
          dataDir = "${config.xdg.dataHome}/vdirsyncer";
          statusDir = "${dataDir}/status";
          calDir = "${dataDir}/calendars";
          tokenFile = "${dataDir}/google_calendar_token";
          configFile = "${config.xdg.configHome}/vdirsyncer/config";
          vdirsyncerBin = "${pkgs.vdirsyncer}/bin/vdirsyncer";

          # vdirsyncer config WITHOUT the client_secret line — and client_secret
          # is the last key of [storage remote], so the activation script can
          # simply append it. Keeping the secret out of this store file is the
          # whole point. `collections = ["from b"]` discovers every calendar
          # Google exposes; metadata syncs colour + display name for DMS.
          vdirsyncerConfigBase = pkgs.writeText "vdirsyncer-config" ''
            [general]
            status_path = "${statusDir}"

            [pair google]
            a = "local"
            b = "remote"
            collections = ["from b"]
            metadata = ["color", "displayname"]
            conflict_resolution = "b wins"

            [storage local]
            type = "filesystem"
            path = "${calDir}"
            fileext = ".ics"

            [storage remote]
            type = "google_calendar"
            token_file = "${tokenFile}"
            client_id = "${cfg.clientId}"
          '';
        in
        {
          home.packages = [ pkgs.vdirsyncer pkgs.khal ];

          # khal carries no secret → a normal store symlink is fine. It discovers
          # every .ics collection vdirsyncer writes under calDir, which is the
          # tree DMS's enableCalendarEvents reads.
          xdg.configFile."khal/config".text = ''
            [calendars]

            [[google]]
            path = ${calDir}/*
            type = discover

            [locale]
            timeformat = %H:%M
            dateformat = %Y-%m-%d
            longdateformat = %Y-%m-%d
            datetimeformat = %Y-%m-%d %H:%M
            longdatetimeformat = %Y-%m-%d %H:%M
            firstweekday = 0
          '';

          # Write the vdirsyncer config at activation with the client secret
          # appended from clientSecretFile (mode 0600, never in the store).
          # `printf` writes the value straight to the file: it is a bash builtin,
          # so the secret is not passed as a process argument and is not echoed —
          # it never reaches stdout or the activation log. The secret's own file
          # remains the trust boundary.
          home.activation.dankCalendarVdirsyncerConfig =
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              install -d -m700 \
                "${dataDir}" "${statusDir}" "${calDir}" \
                "$(dirname ${lib.escapeShellArg configFile})"
              _secret="$(cat ${lib.escapeShellArg cfg.clientSecretFile})"
              (
                umask 077
                cat ${vdirsyncerConfigBase} > ${lib.escapeShellArg configFile}
                printf 'client_secret = "%s"\n' "$_secret" >> ${lib.escapeShellArg configFile}
              )
              unset _secret
            '';

          # Periodic sync. Oneshot: vdirsyncer exits after syncing. It fails
          # (logged, harmless) until the one-time `vdirsyncer discover` writes
          # the OAuth token via the browser grant — see docs/dank-calendar.md.
          systemd.user.services.vdirsyncer = {
            Unit.Description = "vdirsyncer calendar sync (Google → khal)";
            Service = {
              Type = "oneshot";
              ExecStart = "${vdirsyncerBin} -c ${configFile} sync";
            };
          };
          systemd.user.timers.vdirsyncer = {
            Unit.Description = "Periodic vdirsyncer calendar sync";
            Timer = {
              OnBootSec = "2m";
              OnUnitActiveSec = cfg.syncInterval;
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        })
    ];
  };
}
