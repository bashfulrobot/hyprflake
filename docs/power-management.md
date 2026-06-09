# Power Management Reference

Hyprflake provides comprehensive power management options for both desktop and laptop systems.

## Idle Management (DankMaterialShell)

Idle is handled by DankMaterialShell's idle daemon (hypridle was retired). The
same `hyprflake.desktop.idle.*` options drive it; the `dank` module mirrors
them onto DMS's AC and battery timeout settings (`acLockTimeout` /
`acMonitorTimeout` / `acSuspendTimeout` and the battery variants). DMS locks
before suspend and honors `loginctl lock-session`.

Configure screen locking, display power-off, and system suspend timeouts (each
in seconds; `0` disables that step):

```nix
hyprflake.desktop.idle = {
  lockTimeout = 300;      # Lock screen after 5 minutes (default)
  dpmsTimeout = 360;      # Turn off displays after 6 minutes (default; 0 keeps screen on)
  suspendTimeout = 600;   # Suspend after 10 minutes (default, set to 0 to disable)
};
```

### AC and battery ladders

DMS keeps separate idle ladders for AC and battery power. The three options
above feed the AC ladder. To run a tighter ladder on battery, set the
`battery*` overrides:

```nix
hyprflake.desktop.idle = {
  # AC ladder (relaxed):
  lockTimeout = 300;
  dpmsTimeout = 360;
  suspendTimeout = 600;

  # Battery ladder (aggressive):
  batteryLockTimeout = 120;     # Lock after 2 minutes on battery
  batteryDpmsTimeout = 150;     # Screen off after 2.5 minutes on battery
  batterySuspendTimeout = 300;  # Suspend after 5 minutes on battery
};
```

Each `battery*` option defaults to `null`, which means "use the AC value", so a
config that sets only the three base options runs the same ladder on both power
sources (the prior behavior). An explicit `0` disables that step on battery, so
`0` and `null` are not the same: `0` is off, `null` tracks AC. `batteryDpmsTimeout`
drives DMS's `batteryMonitorTimeout`, mirroring how `dpmsTimeout` drives
`acMonitorTimeout`.

**Disable automatic suspend (desktop systems):**

```nix
hyprflake.desktop.idle.suspendTimeout = 0;
```

**Note:** display power-off (DPMS) was disabled by default under hypridle
because OS-driven DPMS was unreliable across some GPU/cable/monitor
combinations. Under DMS the default is `360`. If a host black-screens and does
not wake cleanly, diagnose the GPU/cable path rather than disabling it; set
`dpmsTimeout = 0` per host only as a last resort.

## Laptop Hosts (`isLaptop`)

```nix
hyprflake.system.isLaptop = true;
```

Mark a host as a laptop. This is the single switch for laptop-only battery
behaviour:

- **UPower** is enabled so DankMaterialShell can read battery state — even when
  `profilesBackend = "none"` (e.g. when TLP comes from a `nixos-hardware`
  laptop profile rather than from hyprflake). Without UPower the DMS battery
  widget renders only an icon with no charge percentage.
- The **DMS battery bar widget** is shown. DMS has no separate power-profile
  widget — the battery widget *is* the power-profile control (scroll to switch
  profiles, click for the battery/profile popout), so this one flag governs
  both. Desktops (`isLaptop = false`, the default) get neither.

UPower is also enabled automatically whenever `profilesBackend` is set to a
non-`none` value, since the profile UI lives in the battery popout.

Setting `isLaptop = true` also defaults `power.profilesBackend` to
`power-profiles-daemon`. The DMS battery applet switches power profiles over the
power-profiles-daemon D-Bus interface, so without that backend the applet's
profile control fails. Set `profilesBackend` explicitly to override (for example
`"tlp"` for granular tuning, at the cost of bar profile switching).

Changing the bar widget list takes effect only after a DMS restart:
`systemctl --user restart dms.service`.

## Power Profiles

The backend defaults to `power-profiles-daemon` on laptops and `none` elsewhere
(see `isLaptop` above). Choose between power-profiles-daemon (modern, simple,
drives the DMS applet) or TLP (advanced, granular, but the DMS applet cannot
switch profiles under it).

**Note:** power-profiles-daemon and TLP are mutually exclusive. Choose one.

### power-profiles-daemon (recommended for laptops)

```nix
hyprflake.system.power.profilesBackend = "power-profiles-daemon";
```

Features:

- Three profiles: Performance, Balanced, Power-saver
- Automatic CPU governor and GPU power state management
- Surfaced through the DankMaterialShell control center

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

### Battery charge thresholds without `profilesBackend = "tlp"`

`battery.startThreshold` / `battery.stopThreshold` are applied whenever TLP is
active — not only when hyprflake selects the TLP backend. If TLP comes from a
`nixos-hardware` laptop profile (which is common on ThinkPads), you can keep
`profilesBackend = "none"` and still cap the charge:

```nix
# profilesBackend stays "none"; TLP is provided by the nixos-hardware profile.
hyprflake.system.power.battery = {
  startThreshold = 75;  # Resume charging below 75%
  stopThreshold = 80;   # Stop charging at 80% to extend lifespan
};
```

The thresholds are merged into `services.tlp.settings`, so they compose with
whatever the hardware profile already configures. They take effect only when
`services.tlp.enable` is true and the hardware supports charge control.

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
  idleAction = "ignore";             # Idle action (default: handled by DankMaterialShell)
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
  # Disable suspend in the DankMaterialShell idle daemon (lock + DPMS only)
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
