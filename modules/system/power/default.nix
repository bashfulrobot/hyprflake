{ config, lib, ... }:

let
  # systemd-logind action enum, shared across handlePowerKey, handleLidSwitch,
  # handleLidSwitchDocked, and idleAction. See logind.conf(5) HandlePowerKey=.
  logindAction = lib.types.enum [
    "ignore"
    "poweroff"
    "reboot"
    "halt"
    "kexec"
    "suspend"
    "hibernate"
    "hybrid-sleep"
    "suspend-then-hibernate"
    "lock"
  ];
in
{
  # Power Management Module Aggregator
  # Imports all power management related modules

  # Host classification. Laptop-only desktop features (the DMS battery /
  # power-profile bar widget) and battery monitoring (UPower) gate on this.
  # Declared here rather than in its own module because every effect it has is
  # power/battery-domain; consumers set it per host.
  options.hyprflake.system.isLaptop = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Whether this host is a laptop.

      When true:
      - UPower is enabled so DankMaterialShell can read battery state, even
        when profilesBackend = "none".
      - The DMS bar shows the battery widget (which doubles as the
        power-profile control: scroll to switch profiles, click for the
        battery/profile popout).

      Desktops should leave this at false (default): no battery widget, no
      UPower in the closure.
    '';
  };

  options.hyprflake.system.power = {
    # Power profile management (mutually exclusive options)
    profilesBackend = lib.mkOption {
      type = lib.types.enum [ "none" "power-profiles-daemon" "tlp" ];
      default = "none";
      example = "power-profiles-daemon";
      description = ''
        Power profile management backend to use.

        Options:
        - "none": No automatic power profile management (default)
        - "power-profiles-daemon": Modern power management (recommended for laptops)
        - "tlp": Advanced laptop power management with more granular control

        Note: power-profiles-daemon and tlp are mutually exclusive.
        Choose power-profiles-daemon for simplicity, TLP for advanced tuning.
      '';
    };

    # TLP settings (only used when profilesBackend = "tlp")
    tlp = {
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        example = lib.literalExpression ''
          {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            START_CHARGE_THRESH_BAT0 = 20;
            STOP_CHARGE_THRESH_BAT0 = 80;
          }
        '';
        description = ''
          TLP configuration settings.
          Only applies when profilesBackend = "tlp".

          See TLP documentation for all available settings:
          https://linrunner.de/tlp/settings/
        '';
      };
    };

    # Thermal management
    thermald = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable thermald thermal management daemon.
          Recommended for Intel CPUs to prevent overheating.

          Thermald monitors and controls CPU temperature through
          P-states, T-states, and cooling device adjustments.
        '';
      };
    };

    # Sleep/hibernate configuration
    sleep = {
      hibernateDelay = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "2h";
        description = ''
          Delay before hibernating after suspend (suspend-then-hibernate).
          Format: "30min", "1h", "2h", etc.

          If set, system will suspend first, then automatically hibernate
          after the specified delay to preserve battery on long idle periods.

          Requires swap to be configured for hibernation.
          Set to null to disable suspend-then-hibernate behavior.
        '';
      };

      allowSuspend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Allow system suspend via systemd.
          Set to false to disable suspend functionality system-wide.
          Useful for desktop systems that should never suspend.
        '';
      };

      allowHibernation = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Allow system hibernation via systemd.
          Set to false to disable hibernation functionality system-wide.
        '';
      };
    };

    # Resume hooks
    resumeCommands = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        # Restart network manager
        systemctl restart NetworkManager
      '';
      description = ''
        Shell commands to execute after system resumes from suspend/hibernate.
        Useful for restarting services or fixing hardware state after resume.
      '';
    };

    # Battery charge thresholds (laptop-specific)
    battery = {
      startThreshold = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 20;
        description = ''
          Battery charge start threshold (percentage).
          Battery will only start charging when below this percentage.

          Supported on some laptops (ThinkPad, Dell, etc.) when using TLP.
          Applied whenever TLP is active — either via profilesBackend = "tlp"
          or when TLP is supplied by a nixos-hardware laptop profile — plus
          hardware support. Set to null to disable.
        '';
      };

      stopThreshold = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 80;
        description = ''
          Battery charge stop threshold (percentage).
          Battery will stop charging when reaching this percentage.

          Extending battery lifespan by limiting charge to 80% is recommended
          for laptops that are frequently plugged in.

          Supported on some laptops (ThinkPad, Dell, etc.) when using TLP.
          Applied whenever TLP is active — either via profilesBackend = "tlp"
          or when TLP is supplied by a nixos-hardware laptop profile — plus
          hardware support. Set to null to disable.
        '';
      };
    };

    # Logind power event handling
    logind = {
      handlePowerKey = lib.mkOption {
        type = logindAction;
        default = "poweroff";
        example = "suspend";
        description = ''
          Action to take when the power button is pressed.

          Options:
          - "poweroff": Shut down the system (default)
          - "suspend": Suspend to RAM
          - "hibernate": Hibernate to disk
          - "lock": Lock the session
          - "ignore": Do nothing
        '';
      };

      handleLidSwitch = lib.mkOption {
        type = logindAction;
        default = "suspend";
        example = "lock";
        description = ''
          Action to take when the laptop lid is closed.

          Options:
          - "suspend": Suspend to RAM (default)
          - "lock": Lock the session (recommended for desktops with lid switch)
          - "ignore": Do nothing
          - "poweroff": Shut down the system
        '';
      };

      handleLidSwitchDocked = lib.mkOption {
        type = logindAction;
        default = "ignore";
        example = "ignore";
        description = ''
          Action to take when the laptop lid is closed while docked.
          Default is "ignore" (no action when external displays are connected).
        '';
      };

      idleAction = lib.mkOption {
        type = logindAction;
        default = "ignore";
        example = "suspend";
        description = ''
          Action to take when the system is idle.
          Default is "ignore" (idle is handled by the DankMaterialShell idle
          daemon via hyprflake.desktop.idle.*).

          Note: If set to something other than "ignore", this takes precedence
          over the shell's idle management. Prefer hyprflake.desktop.idle.* for
          more granular control.
        '';
      };

      idleActionSec = lib.mkOption {
        type = lib.types.int;
        default = 0;
        example = 1800;
        description = ''
          Idle timeout in seconds before idleAction is triggered.
          Set to 0 to disable (default).

          Only relevant if idleAction is not "ignore".
          Recommended to keep at 0 and use hyprflake.desktop.idle.* instead.
        '';
      };
    };
  };

  # UPower drives DMS battery monitoring. Enabled for any laptop, and for any
  # host that selects a power-profile backend (profilesBackend ships upower
  # because the profile UI lives in the battery popout). Centralised here so
  # the enablement is not duplicated across tlp.nix / profiles-daemon.nix.
  config.services.upower.enable = lib.mkIf
    (config.hyprflake.system.isLaptop
      || config.hyprflake.system.power.profilesBackend != "none")
    true;

  imports = [
    ./idle.nix
    ./profiles-daemon.nix
    ./tlp.nix
    ./thermal.nix
    ./sleep.nix
    ./logind.nix
  ];
}
