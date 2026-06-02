{ config, lib, pkgs, hyprflakeInputs, ... }:

# Update checks - surface when a newer DankMaterialShell or Hyprland is
# available, on the workstation that consumes this flake.
#
# DMS is pinned to a master commit until a release carries the Lua-config
# dispatch fix (see docs/workarounds.md), and Hyprland comes from nixpkgs,
# which lags upstream. A systemd user timer polls GitHub's public release API,
# writes a status file, sends a DMS notification when something is actionable,
# and an interactive fish session prints a one-line notice. The pull-side
# equivalent that runs in the flake repo is `just dms-check`.

let
  cfg = config.hyprflake.desktop.updateChecks;

  dmsPkg = hyprflakeInputs.dank-material-shell.packages.${pkgs.system}.dms-shell;
  dmsRev = hyprflakeInputs.dank-material-shell.rev or "unknown";

  updatesScript = pkgs.writeShellApplication {
    name = "hyprflake-updates";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.libnotify
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = builtins.replaceStrings
      [ "@@DMS_VERSION@@" "@@DMS_REV@@" "@@HYPR_VERSION@@" ]
      [ dmsPkg.version dmsRev pkgs.hyprland.version ]
      (builtins.readFile ./hyprflake-updates.sh);
  };
in
{
  options.hyprflake.desktop.updateChecks = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Periodically check whether a newer DankMaterialShell or Hyprland is
        available and surface it on the workstation (a DMS notification plus an
        interactive-shell notice). DMS is pinned to a master commit until a
        release carries the Lua-config dispatch fix (docs/workarounds.md); this
        flags when that release lands. Pull-side analog: `just dms-check`.
      '';
    };

    notify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Send a desktop notification (via DMS) when updates are found.";
    };

    shellNotice = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Print a one-line notice in interactive fish sessions when updates are pending.";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd OnCalendar expression for the periodic check.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Installed system-wide so the user and consumer justfiles (e.g. a
    # post-rebuild note) can call `hyprflake-updates` directly.
    environment.systemPackages = [ updatesScript ];

    home-manager.sharedModules = [
      (_: {
        systemd.user.services.hyprflake-updates = {
          Unit.Description = "Check for DankMaterialShell / Hyprland updates";
          Service = {
            Type = "oneshot";
            ExecStart =
              "${updatesScript}/bin/hyprflake-updates"
              + lib.optionalString cfg.notify " --notify";
          };
        };

        systemd.user.timers.hyprflake-updates = {
          Unit.Description = "Periodic DankMaterialShell / Hyprland update check";
          Timer = {
            OnStartupSec = "5min";
            OnCalendar = cfg.onCalendar;
            Persistent = true;
            RandomizedDelaySec = "30min";
          };
          Install.WantedBy = [ "timers.target" ];
        };

        xdg.configFile = lib.mkIf cfg.shellNotice {
          "fish/conf.d/hyprflake-updates.fish".text = ''
            # One-line notice when the hyprflake-updates timer has flagged a
            # pending DankMaterialShell / Hyprland update. The status file is
            # written by the timer to $XDG_STATE_HOME/hyprflake/updates.txt.
            if status is-interactive
                set -l _hf_state $XDG_STATE_HOME
                test -z "$_hf_state"; and set _hf_state $HOME/.local/state
                set -l _hf_file $_hf_state/hyprflake/updates.txt
                if test -s $_hf_file
                    set_color yellow
                    echo "hyprflake: update(s) available - run hyprflake-updates"
                    set_color normal
                end
            end
          '';
        };
      })
    ];
  };
}
