{ config, lib, ... }:

{
  # Logind Power Event Handling
  # Controls system responses to power button, lid switch, and idle events
  # Configured via hyprflake.system.power.logind options

  config = {
    services.logind.settings.Login = {
      HandlePowerKey = config.hyprflake.system.power.logind.handlePowerKey;
      HandleLidSwitch = config.hyprflake.system.power.logind.handleLidSwitch;
      HandleLidSwitchDocked = config.hyprflake.system.power.logind.handleLidSwitchDocked;
      IdleAction = config.hyprflake.system.power.logind.idleAction;
      IdleActionSec = toString config.hyprflake.system.power.logind.idleActionSec;
    };
  };
}
