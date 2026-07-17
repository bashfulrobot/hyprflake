{ config, lib, pkgs, hyprflakeInputs, ... }:

# Update checks - surface when a newer DankMaterialShell, Hyprland,
# dms-emoji-launcher, or Voxtype is available, on the workstation that consumes
# this flake.
#
# The actionable signal: a pinned input has a newer upstream release/commit
# than what this flake currently builds - actionable via `just bump`/`just
# update-input`. Hyprland and the DMS shell both come from nixpkgs, which lags
# upstream, so their signal is "nixpkgs now ships newer than what this flake
# builds", not "upstream tagged a release" - nothing is bumpable until nixpkgs
# catches up. DMS is checked twice, since its shell package (nixpkgs) and its
# module pin (the dank-material-shell input) move independently.
# dms-emoji-launcher is pinned to a frozen commit
# on its default branch; Voxtype tracks release tags. A systemd user timer
# polls GitHub's public API, writes a status file, sends a DMS notification
# when something is actionable, and an interactive fish session prints a
# one-line notice.

let
  cfg = config.hyprflake.desktop.updateChecks;

  # The shell that actually runs. modules/desktop/dank sets
  # programs.dank-material-shell.package = pkgs.dms-shell, so the built version
  # tracks nixpkgs, not the pin. Reading the version off the *input* here made
  # the check report "up to date" whenever the pin was current, even with an
  # older nixpkgs shell installed.
  dmsPkg = pkgs.dms-shell;

  # The pin, which supplies only the home-manager module and the greeter
  # nixosModule. Tracked separately so `just bump dank-material-shell` still
  # gets flagged when a release moves those, without implying the shell moved.
  dmsPinVersion =
    hyprflakeInputs.dank-material-shell.packages.${pkgs.system}.dms-shell.version;

  emojiRev = hyprflakeInputs.dms-emoji-launcher.rev or "unknown";
  voxtypeVersion =
    hyprflakeInputs.voxtype.packages.${pkgs.system}.default.version or "unknown";

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
      [ "@@DMS_VERSION@@" "@@DMS_PIN_VERSION@@" "@@HYPR_VERSION@@" "@@EMOJI_REV@@" "@@VOXTYPE_VERSION@@" ]
      [ dmsPkg.version dmsPinVersion pkgs.hyprland.version emojiRev voxtypeVersion ]
      (builtins.readFile ./hyprflake-updates.sh);
  };
in
{
  options.hyprflake.desktop.updateChecks = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Periodically check whether a newer DankMaterialShell, Hyprland,
        dms-emoji-launcher, or Voxtype is available and surface it on the
        workstation (a DMS notification plus an interactive-shell notice).
        Flags newer releases of pinned inputs (actionable via `just bump`).
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
