{ config
, lib
, pkgs
, ...
}:

# Calendar Takeover - Fullscreen, persistent notifications for Google Calendar
# Hooks swaync so matching notifications are suppressed as corner popups
# and instead displayed as a Wayland layer-shell OVERLAY that blocks input
# until the user clicks Dismiss (or presses Escape / Enter).

let
  cfg = config.hyprflake.desktop.calendar-notifier;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };

  cssFile = pkgs.writeText "calendar-takeover.css" (stylix.mkStyle ./style.nix);

  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.gtk4
    pkgs.gtk4-layer-shell
    pkgs.glib.out
    pkgs.pango.out
    pkgs.gdk-pixbuf.out
    pkgs.graphene
    pkgs.harfbuzz.out
    pkgs.cairo.out
  ];

  takeoverPython = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);

  takeoverScript = pkgs.writeShellApplication {
    name = "calendar-takeover";
    runtimeInputs = [
      takeoverPython
      pkgs.gtk4
      pkgs.gtk4-layer-shell
    ];
    text = ''
      export GI_TYPELIB_PATH="${giTypelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      export LD_LIBRARY_PATH="${pkgs.gtk4-layer-shell}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export CALENDAR_TAKEOVER_CSS="${cssFile}"
      export CALENDAR_TAKEOVER_DISMISS="${cfg.dismissLabel}"
      export CALENDAR_TAKEOVER_DEBUG="${if cfg.debug then "1" else "0"}"
      exec ${takeoverPython}/bin/python3 ${./takeover.py} "$@"
    '';
  };

  visibilityRule = {
    name = "calendar-takeover-suppress";
    app-name = cfg.appNameRegex;
    summary = cfg.summaryRegex;
    state = "ignored";
  };
in
{
  options.hyprflake.desktop.calendar-notifier = {
    enable = lib.mkEnableOption "Fullscreen takeover popups for Google Calendar notifications";

    appNameRegex = lib.mkOption {
      type = lib.types.str;
      default = "^(Chromium|Google Chrome|google-chrome|chrome|Google Calendar)$";
      description = ''
        Regex matched against the notification's app-name. Covers Chromium-family
        browsers plus the Google Calendar label if ever distinct. ANDed with
        summaryRegex. Set debug = true to discover the actual app-name sent by
        your browser.
      '';
    };

    summaryRegex = lib.mkOption {
      type = lib.types.str;
      default = "(^Event reminder)|( in [0-9]+ minutes?$)|(^Now:)|(calendar\\.google\\.com)";
      description = ''
        Regex matched against the notification summary. ANDed with appNameRegex.
        Google Calendar's default reminder wording covers "Event reminder:",
        "<title> in N minutes", and "Now: <title>".
      '';
    };

    suppressNormalPopup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Prevent swaync from also rendering the matched notification as a normal
        corner popup. The takeover still runs. Disable briefly while tuning
        regexes to see both at once.
      '';
    };

    dismissLabel = lib.mkOption {
      type = lib.types.str;
      default = "Dismiss";
      description = "Text on the dismiss button.";
    };

    panicBind = lib.mkOption {
      type = lib.types.str;
      default = "SUPER SHIFT, X";
      description = ''
        Hyprland bind that force-closes the takeover via pkill. Required because
        the overlay grabs exclusive keyboard input - this is your escape hatch
        if the script ever hangs. Set to "" to disable.
      '';
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Log every received notification (app-name / summary / body) to
        ~/.cache/calendar-takeover.log. Use when tuning regexes.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.hyprflake.desktop.swaync.enable;
        message = "hyprflake.desktop.calendar-notifier requires hyprflake.desktop.swaync.enable = true.";
      }
    ];

    home-manager.sharedModules = [
      (_: {
        services.swaync.settings = {
          scripts.calendar-takeover = {
            exec = lib.getExe takeoverScript;
            app-name = cfg.appNameRegex;
            summary = cfg.summaryRegex;
            run-on = "received";
          };
        } // lib.optionalAttrs cfg.suppressNormalPopup {
          notification-visibility = [ visibilityRule ];
        };

        xdg.configFile."hypr/conf.d/calendar-notifier.conf".text = ''
          # Calendar takeover overlay rules (managed by hyprflake.desktop.calendar-notifier)
          layerrule = noanim, ^(calendar-takeover)$
          layerrule = blur, ^(calendar-takeover)$
        '' + lib.optionalString (cfg.panicBind != "") ''

          # Panic escape: exclusive keyboard grab can't block this compositor-level bind
          bind = ${cfg.panicBind}, exec, ${pkgs.procps}/bin/pkill -f calendar-takeover
        '';
      })
    ];
  };
}
