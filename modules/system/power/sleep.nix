{ config, lib, ... }:

{
  # Sleep and Hibernate Configuration
  # Controls system suspend, hibernation, and suspend-then-hibernate behavior
  # Supports disabling suspend/hibernate entirely for desktop systems

  config = lib.mkMerge [
    # Hibernate delay configuration (suspend-then-hibernate)
    (lib.mkIf (config.hyprflake.system.power.sleep.hibernateDelay != null) {
      systemd.sleep.extraConfig = ''
        HibernateDelaySec=${config.hyprflake.system.power.sleep.hibernateDelay}
      '';
    })

    # Disable suspend if configured
    (lib.mkIf (!config.hyprflake.system.power.sleep.allowSuspend) {
      systemd.sleep.extraConfig = ''
        AllowSuspend=no
        AllowSuspendThenHibernate=no
      '';
    })

    # Disable hibernation if configured
    (lib.mkIf (!config.hyprflake.system.power.sleep.allowHibernation) {
      systemd.sleep.extraConfig = ''
        AllowHibernation=no
        AllowSuspendThenHibernate=no
        AllowHybridSleep=no
      '';
    })

    # Resume commands hook
    (lib.mkIf (config.hyprflake.system.power.resumeCommands != "") {
      powerManagement.resumeCommands = config.hyprflake.system.power.resumeCommands;
    })
  ];
}
