{ lib, ... }:

# Idle timeout policy (lock / display-off / suspend). This is power-management
# policy, so it lives with the power module rather than the shell. The shell
# (modules/desktop/dank) reads these values to configure its idle daemon.
#
# The option path stays `hyprflake.desktop.idle.*` (not `system.power.idle.*`)
# to keep the consumer-facing API stable — moving the declaration here does not
# change what consumers set.

{
  options.hyprflake.desktop.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 300;
      example = 600;
      description = "Seconds before locking the session. 0 disables.";
    };
    dpmsTimeout = lib.mkOption {
      type = lib.types.int;
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
      type = lib.types.int;
      default = 600;
      example = 0;
      description = "Seconds before suspend. 0 disables.";
    };
  };
}
