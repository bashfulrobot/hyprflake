{ config, lib, ... }:

{
  # Power Profiles Daemon
  # Modern power management with Performance/Balanced/Power-saver profiles
  # Automatically manages CPU governors, GPU power states, and system performance

  config = lib.mkIf (config.hyprflake.system.power.profilesBackend == "power-profiles-daemon") {
    services = {
      power-profiles-daemon.enable = true;

      # Ensure TLP is not enabled (mutually exclusive)
      tlp.enable = false;

      # UPower (battery monitoring) is enabled centrally in default.nix for any
      # laptop or any host with a profilesBackend.
    };
  };
}
