{ config, lib, ... }:

# DEPRECATED: removed in the DankMaterialShell migration. calendar-notifier
# hooked the swaync notification daemon (also retired), so it no longer
# functions. This is an options-only stub kept so consumers that still set
# hyprflake.desktop.calendar-notifier.* keep evaluating; it emits a no-op
# warning. Remove the option from your config when convenient.

let
  cfg = config.hyprflake.desktop.calendar-notifier;
in
{
  options.hyprflake.desktop.calendar-notifier = {
    enable = lib.mkEnableOption "Fullscreen takeover popups for Google Calendar notifications";

    appNameRegex = lib.mkOption {
      type = lib.types.str;
      default = "^(Chromium|Google Chrome|google-chrome|chrome|Google Calendar)$";
      description = "DEPRECATED no-op. Regex matched against the notification's app-name.";
    };

    bodyRegex = lib.mkOption {
      type = lib.types.str;
      default = "calendar\\.google\\.com";
      description = "DEPRECATED no-op. Regex matched against the notification body.";
    };

    suppressNormalPopup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "DEPRECATED no-op. Previously hid the normal swaync popup for matched notifications.";
    };

    dismissLabel = lib.mkOption {
      type = lib.types.str;
      default = "Dismiss";
      description = "DEPRECATED no-op. Text on the dismiss button.";
    };

    calendarUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://accounts.google.com/AccountChooser?continue=https%3A%2F%2Fcalendar.google.com%2Fcalendar%2Fr%2Fday";
      description = "DEPRECATED no-op. URL opened by the single \"Open Calendar\" button.";
    };

    accounts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          label = lib.mkOption {
            type = lib.types.str;
            description = "Short name shown in the picker (e.g. \"Work\").";
          };
          url = lib.mkOption {
            type = lib.types.str;
            description = "URL to open for this account, typically with a /u/N/ index.";
          };
        };
      });
      default = [ ];
      example = [
        { label = "Work"; url = "https://calendar.google.com/calendar/u/0/r/day"; }
        { label = "Personal"; url = "https://calendar.google.com/calendar/u/1/r/day"; }
      ];
      description = "DEPRECATED no-op. Optional list of calendar accounts for the picker.";
    };

    panicBind = lib.mkOption {
      type = lib.types.str;
      default = "SUPER SHIFT, X";
      description = "DEPRECATED no-op. Hyprland bind that force-closed the takeover.";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "DEPRECATED no-op. Logged received notifications for regex tuning.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      "hyprflake.desktop.calendar-notifier is a no-op: it hooked swaync, which was retired in the DankMaterialShell migration. Remove this option from your config."
    ];
  };
}
