{ lib, ... }:

# Idle timeout policy (lock / display-off / suspend). This is power-management
# policy, so it lives with the power module rather than the shell. The shell
# (modules/desktop/dank) reads these values to configure its idle daemon.
#
# The option path stays `hyprflake.desktop.idle.*` (not `system.power.idle.*`)
# to keep the consumer-facing API stable — moving the declaration here does not
# change what consumers set.

{
  # Timeouts are seconds and never negative. The type is ints.unsigned (not
  # plain int) so a nonsensical negative is an eval error rather than silently
  # disabling the step: DMS's IdleService arms each listener only when its
  # timeout is > 0, so it treats 0 and any negative the same (off). Constraining
  # to unsigned keeps 0 as the single, documented "disable" value.
  options.hyprflake.desktop.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 300;
      example = 600;
      description = "Seconds before locking the session. 0 disables.";
    };
    dpmsTimeout = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 360;
      example = 0;
      description = ''
        Seconds before turning displays off (DPMS). 0 disables.
        DMS drives this through the compositor's monitor power-off
        (acMonitorTimeout / batteryMonitorTimeout). Defaults to 360
        (6 minutes); set 0 to keep the screen on.
      '';
    };
    suspendTimeout = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 600;
      example = 0;
      description = "Seconds before suspend. 0 disables.";
    };

    # Battery-specific overrides. DMS supports distinct AC and battery idle
    # ladders; the three options above feed the AC settings, these feed the
    # battery settings. Each defaults to null, which means "track the AC value"
    # (resolved in the dank module), so a config that sets only the AC options
    # behaves exactly as before. An explicit 0 disables that step on battery
    # (DMS treats 0 and unset identically), so 0 and null are not the same here:
    # 0 means "off on battery", null means "same as AC".
    batteryLockTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      example = 120;
      description = ''
        Seconds before locking the session on battery. null tracks
        lockTimeout (the AC value); 0 disables locking on battery.
      '';
    };
    batteryDpmsTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      example = 150;
      description = ''
        Seconds before turning displays off (DPMS) on battery. null tracks
        dpmsTimeout (the AC value); 0 keeps the screen on while on battery.
        Wired to DMS's batteryMonitorTimeout.
      '';
    };
    batterySuspendTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      example = 300;
      description = ''
        Seconds before suspend on battery. null tracks suspendTimeout (the AC
        value); 0 disables suspend on battery.
      '';
    };
  };
}
