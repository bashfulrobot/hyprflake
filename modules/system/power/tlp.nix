{ config, lib, ... }:

let
  cfg = config.hyprflake.system.power;
  inherit (cfg.battery) startThreshold stopThreshold;

  # Battery charge-threshold keys, derived from the battery.*Threshold options.
  # Empty when neither threshold is set.
  thresholdSettings =
    lib.optionalAttrs (startThreshold != null)
      {
        START_CHARGE_THRESH_BAT0 = startThreshold;
        START_CHARGE_THRESH_BAT1 = startThreshold;
      } // lib.optionalAttrs (stopThreshold != null) {
      STOP_CHARGE_THRESH_BAT0 = stopThreshold;
      STOP_CHARGE_THRESH_BAT1 = stopThreshold;
    };
in
{
  # TLP - Advanced Power Management for Laptops
  # Provides granular control over CPU, disk, USB, and battery settings
  # Includes support for battery charge thresholds on supported hardware

  config = lib.mkMerge [
    # hyprflake-managed TLP backend, selected via profilesBackend = "tlp".
    (lib.mkIf (cfg.profilesBackend == "tlp") {
      services = {
        tlp = {
          enable = true;
          settings = cfg.tlp.settings;
        };

        # Ensure power-profiles-daemon is not enabled (mutually exclusive)
        power-profiles-daemon.enable = false;

        # UPower (battery monitoring) is enabled centrally in default.nix for
        # any laptop or any host with a profilesBackend.
      };
    })

    # Battery charge thresholds apply whenever TLP is active — including when
    # TLP comes from a nixos-hardware laptop profile rather than from
    # hyprflake's own profilesBackend. services.tlp.settings is an attrset, so
    # this merges with (and does not clobber) the hardware profile's settings.
    (lib.mkIf (config.services.tlp.enable && thresholdSettings != { }) {
      services.tlp.settings = thresholdSettings;
    })
  ];
}
