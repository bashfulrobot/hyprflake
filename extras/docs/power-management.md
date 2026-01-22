# Power Management Reference

Hyprflake provides comprehensive power management options for both desktop and laptop systems.

## Idle Management (Hypridle)

Configure screen locking, display power management, and system suspend timeouts:

```nix
hyprflake.desktop.idle = {
  lockTimeout = 300;      # Lock screen after 5 minutes (default)
  dpmsTimeout = 360;      # Turn off display after 6 minutes (default)
  suspendTimeout = 600;   # Suspend after 10 minutes (default, set to 0 to disable)
};
```

**Disable automatic suspend (desktop systems):**

```nix
hyprflake.desktop.idle.suspendTimeout = 0;
```

## Power Profiles

Choose between power-profiles-daemon (modern, simple) or TLP (advanced, granular).

**Note:** power-profiles-daemon and TLP are mutually exclusive. Choose one.

### power-profiles-daemon (recommended for laptops)

```nix
hyprflake.system.power.profilesBackend = "power-profiles-daemon";
```

Features:

- Three profiles: Performance, Balanced, Power-saver
- Automatic CPU governor and GPU power state management
- Waybar integration with click-to-cycle profile switching
- Profile icon displayed in system info drawer

### TLP (advanced laptop power management)

```nix
hyprflake.system.power = {
  profilesBackend = "tlp";
  tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  };
  battery = {
    startThreshold = 20;  # Start charging at 20%
    stopThreshold = 80;   # Stop charging at 80%
  };
};
```

Features:

- Granular control over CPU, disk, USB, and network power states
- Battery charge thresholds (ThinkPad, Dell, etc.)
- Per-device power management rules

## Thermal Management (Intel CPUs)

Enable thermald for automatic thermal management:

```nix
hyprflake.system.power.thermald.enable = true;
```

Recommended for Intel laptops to prevent thermal throttling and overheating.

## Sleep and Hibernate

Control system suspend and hibernation behavior:

```nix
hyprflake.system.power.sleep = {
  allowSuspend = true;         # Allow system suspend (default: true)
  allowHibernation = true;     # Allow hibernation (default: true)
  hibernateDelay = "2h";       # Suspend-then-hibernate after 2 hours (default: null)
};
```

**Disable suspend/hibernate (desktop systems):**

```nix
hyprflake.system.power.sleep = {
  allowSuspend = false;
  allowHibernation = false;
};
```

**Enable suspend-then-hibernate (laptops):**

```nix
hyprflake.system.power.sleep.hibernateDelay = "2h";
```

System will suspend normally, then automatically hibernate after 2 hours to preserve battery.

## Logind Power Event Handling

Configure power button and lid switch behavior:

```nix
hyprflake.system.power.logind = {
  handlePowerKey = "poweroff";       # Power button action (default)
  handleLidSwitch = "suspend";       # Lid close action (default)
  handleLidSwitchDocked = "ignore";  # Lid close when docked (default)
  idleAction = "ignore";             # Idle action (default: handled by hypridle)
  idleActionSec = 0;                 # Idle timeout seconds (default: 0)
};
```

**Available actions:** `ignore`, `poweroff`, `suspend`, `hibernate`, `lock`

**Lock on lid close:**

```nix
hyprflake.system.power.logind.handleLidSwitch = "lock";
```

## Resume Commands

Execute commands after waking from suspend/hibernate:

```nix
hyprflake.system.power.resumeCommands = ''
  # Restart network manager
  systemctl restart NetworkManager

  # Fix audio after resume
  systemctl --user restart pipewire
'';
```

## Real-World Examples

### Desktop System (suspend bugs)

Desktop with AMD GPU that has suspend bugs - disable all suspend/hibernate:

```nix
hyprflake = {
  # Disable suspend in hypridle (lock + DPMS only)
  desktop.idle.suspendTimeout = 0;

  # Disable suspend/hibernate system-wide
  system.power.sleep = {
    allowSuspend = false;
    allowHibernation = false;
  };

  # Power button shuts down, lid switch locks (if applicable)
  system.power.logind = {
    handlePowerKey = "poweroff";
    handleLidSwitch = "lock";
  };
};
```

### Laptop System

Laptop with power profiles, battery thresholds, and suspend-then-hibernate:

```nix
hyprflake = {
  # Longer idle timeouts for laptop
  desktop.idle = {
    lockTimeout = 600;      # 10 minutes
    dpmsTimeout = 660;      # 11 minutes
    suspendTimeout = 1200;  # 20 minutes
  };

  # TLP with battery care
  system.power = {
    profilesBackend = "tlp";
    tlp.settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
    battery = {
      startThreshold = 20;
      stopThreshold = 80;  # Extend battery lifespan
    };

    # Suspend for 2 hours, then hibernate to save battery
    sleep.hibernateDelay = "2h";

    # Thermald for Intel CPU
    thermald.enable = true;
  };
};
```
