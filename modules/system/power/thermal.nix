{ config, lib, ... }:

{
  # Thermald - Thermal Management Daemon
  # Monitors and controls CPU temperature through P-states, T-states, and cooling devices
  # Recommended for Intel CPUs to prevent thermal throttling and overheating

  config = lib.mkIf config.hyprflake.system.power.thermald.enable {
    services.thermald.enable = true;
  };
}
