{ config, lib, ... }:

{
  # TLP - Advanced Power Management for Laptops
  # Provides granular control over CPU, disk, USB, and battery settings
  # Includes support for battery charge thresholds on supported hardware

  config = lib.mkIf (config.hyprflake.system.power.profilesBackend == "tlp") {
    services = {
      tlp = {
        enable = true;

        # Merge user settings with battery threshold configuration
        settings = config.hyprflake.system.power.tlp.settings // (
          let
            inherit (config.hyprflake.system.power.battery) startThreshold stopThreshold;
          in
          lib.optionalAttrs (startThreshold != null) {
            START_CHARGE_THRESH_BAT0 = startThreshold;
            START_CHARGE_THRESH_BAT1 = startThreshold;
          } // lib.optionalAttrs (stopThreshold != null) {
            STOP_CHARGE_THRESH_BAT0 = stopThreshold;
            STOP_CHARGE_THRESH_BAT1 = stopThreshold;
          }
        );
      };

      # Ensure power-profiles-daemon is not enabled (mutually exclusive)
      power-profiles-daemon.enable = false;

      # Enable upower for battery monitoring
      upower.enable = true;
    };
  };
}
