# Hyprflake - Reusable Hyprland Flake

A modular and reusable NixOS flake for Hyprland desktop environment with comprehensive theming, GPU optimization, and essential integrations.

## Project Structure

```
hyprflake/
├── flake.nix                           # Main flake with inputs & helper functions
└── modules/
    ├── default.nix                     # Module aggregator
    ├── options.nix                     # Hyprflake configuration options
    ├── desktop/
    │   ├── autostart/                  # XDG autostart support via dex
    │   ├── display-manager/            # GDM login manager
    │   ├── hyprland/                   # Hyprland window manager config
    │   ├── hyprshell/                  # Window switcher (alt-tab)
    │   ├── hypridle/                   # Idle management
    │   ├── hyprlock/                   # Lock screen
    │   ├── rofi/                       # Application launcher
    │   ├── shortcuts-viewer/           # Keybinding and shortcut viewer (rofi/fzf)
    │   ├── stylix/                     # Stylix theming integration
    │   ├── swaync/                     # Notification daemon
    │   ├── swayosd/                    # On-screen display (volume, brightness)
    │   ├── themes/                     # GTK/icon/cursor themes
    │   ├── waybar/                     # Status bar
    │   ├── waybar-auto-hide/           # Waybar auto-hide utility
    │   └── wlogout/                    # Logout menu
    ├── home/
    │   ├── gtk/                        # GTK theme configuration
    │   └── kitty/                      # Terminal emulator
    └── system/
        ├── keyring/                    # GNOME Keyring with SSH auto-discovery
        ├── plymouth/                   # Plymouth boot splash
        ├── power/                      # Power management modules
        │   ├── profiles-daemon.nix     # power-profiles-daemon
        │   ├── tlp.nix                 # TLP (advanced laptop power)
        │   ├── thermal.nix             # thermald (Intel thermal management)
        │   ├── sleep.nix               # Sleep/hibernate configuration
        │   └── logind.nix              # Logind power event handling
        └── user/                       # User account management

```

## Key Features

### 🎨 Unified Theming System

- Theme options configurable once, applied everywhere
- GTK, icon, and cursor themes with dconf integration
- Stylix integration for system-wide theming
- Consistent theming across NixOS and Home Manager
- Plymouth boot splash using the same wallpaper as Hyprland

### 🖥️ GPU Optimization

- Boolean flags for AMD, NVIDIA, and Intel GPUs
- GPU-specific drivers and environment variables
- NVIDIA Wayland optimizations included

### 📦 Complete Desktop Environment

- Hyprland from nixpkgs (stable, tested releases)
- Hyprshell window switcher (alt-tab) from nixpkgs via Home Manager
- Waybar status bar with auto-hide (enabled by default)
- XDG portals configured correctly
- Audio via PipeWire
- Display manager (gdm)
- Essential Wayland utilities included

### 🔄 XDG Autostart Support

- Automatic execution of `.desktop` files via dex
- Enabled by default with `hyprflake.autostart.enable = true`
- Standard XDG autostart directories: `~/.config/autostart/` and `/etc/xdg/autostart/`
- Respects `OnlyShowIn`, `NotShowIn`, `Hidden`, and `TryExec` directives
- Users can add custom autostart applications without modifying Hyprland config

### 🔍 Shortcuts Viewer

- **Dynamic keybinding discovery**: Query `hyprctl` for real-time keybindings and global shortcuts
- **Multiple display modes**: Rofi (GUI) or terminal (fzf) with the same data
- **Fast performance**: Sub-20ms query time, imperceptible to users
- **Human-readable formatting**: Icons, proper spacing, and clear action descriptions
- **Built-in filtering**: Fuzzy search via rofi or fzf
- **Always accurate**: No rebuild needed, reflects current runtime configuration
- **Default keybindings**: Super+? for bindings, Super+Shift+? for global shortcuts

### ⚡ Comprehensive Power Management

- **Configurable idle management**: Customizable timeouts for lock, DPMS, and suspend
- **Power profiles**: Choice between power-profiles-daemon or TLP with Waybar integration
- **Thermal management**: Thermald support for Intel CPUs
- **Sleep control**: Configurable suspend/hibernate behavior with suspend-then-hibernate
- **Logind integration**: Configurable power button and lid switch actions
- **Battery care**: TLP battery charge thresholds for extended battery lifespan
- **Resume hooks**: Execute custom commands after wake from suspend/hibernate

### 🚀 Easy Integration

Helper functions for other flakes:

- `mkHyprlandSystem` - Complete NixOS system
- `mkHyprlandHome` - Home Manager configuration

## Usage Examples

### NixOS System Configuration

```nix
programs.hyprflake = {
  enable = true;
  withUWSM = true;  # Recommended for NixOS 24.11+
  nvidia = true;  # or amd = true; intel = true;
  theme = {
    gtkTheme = "Adwaita-dark";
    iconTheme = "Papirus";
    cursorTheme = "Adwaita";
    cursorSize = 24;
  };
};

programs.hyprflake-dconf.enable = true;
services.hyprflake-display = {
  enable = true;
  autoLogin = "myuser";  # Optional auto-login
};
services.hyprflake-keyring.enable = true;

# Optional: Enable Plymouth boot splash (auto-matches colorScheme)
# Uses Catppuccin Plymouth theme if colorScheme is catppuccin-*,
# otherwise falls back to Circle HUD theme
hyprflake.plymouth.enable = true;

# Optional: Disable Waybar auto-hide (enabled by default)
hyprflake.waybar-auto-hide.enable = false;

# Optional: Disable XDG autostart (enabled by default)
hyprflake.autostart.enable = false;

# Shortcuts viewer (always available)
# Default keybindings: Super+? and Super+Shift+?
# Optional: Change display mode (default is "rofi")
hyprflake.shortcuts-viewer.defaultDisplay = "terminal";
```

### Home Manager Configuration

```nix
wayland.windowManager.hyprflake = {
  enable = true;
  theme = {
    gtkTheme = "Adwaita-dark";
    iconTheme = "Papirus";
    cursorTheme = "Adwaita";
    cursorSize = 24;
  };
};

dconf.hyprflake.enable = true;
services.hyprflake-keyring-hm.enable = true;
```

### Using Helper Functions

```nix
# In another flake
inputs.hyprflake.lib.mkHyprlandSystem {
  extraModules = [
    ./hardware-configuration.nix
    { networking.hostName = "my-system"; }
  ];
}
```

### Using XDG Autostart

Autostart is enabled by default. To add applications that launch automatically:

1. Create a `.desktop` file in `~/.config/autostart/`:

```desktop
[Desktop Entry]
Type=Application
Name=My Application
Exec=/path/to/myapp
Icon=myapp-icon
Comment=My custom application
X-GNOME-Autostart-enabled=true
```

2. Optional directives:
   - `OnlyShowIn=Hyprland;` - Only run in Hyprland
   - `NotShowIn=GNOME;KDE;` - Don't run in these environments
   - `Hidden=true` - Temporarily disable without deleting
   - `TryExec=/path/to/binary` - Only run if binary exists

3. Restart Hyprland or run manually:
```bash
dex --autostart --environment Hyprland
```

Applications will automatically start on next login.

### Power Management Configuration

Hyprflake provides comprehensive power management options for both desktop and laptop systems.

#### Idle Management (Hypridle)

Configure screen locking, display power management, and system suspend timeouts:

```nix
hyprflake.desktop.idle = {
  lockTimeout = 300;      # Lock screen after 5 minutes (default)
  dpmsTimeout = 360;      # Turn off display after 6 minutes (default)
  suspendTimeout = 600;   # Suspend after 10 minutes (default, set to 0 to disable)
};
```

**Example: Disable automatic suspend (desktop systems):**
```nix
hyprflake.desktop.idle.suspendTimeout = 0;
```

#### Power Profiles

Choose between power-profiles-daemon (modern, simple) or TLP (advanced, granular):

**Option 1: power-profiles-daemon (recommended for laptops)**
```nix
hyprflake.system.power.profilesBackend = "power-profiles-daemon";
```

Features:
- Three profiles: Performance, Balanced, Power-saver
- Automatic CPU governor and GPU power state management
- Waybar integration with click-to-cycle profile switching
- Profile icon displayed in system info drawer

**Option 2: TLP (advanced laptop power management)**
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

**Note:** power-profiles-daemon and TLP are mutually exclusive. Choose one.

#### Thermal Management (Intel CPUs)

Enable thermald for automatic thermal management:

```nix
hyprflake.system.power.thermald.enable = true;
```

Recommended for Intel laptops to prevent thermal throttling and overheating.

#### Sleep and Hibernate

Control system suspend and hibernation behavior:

```nix
hyprflake.system.power.sleep = {
  allowSuspend = true;         # Allow system suspend (default: true)
  allowHibernation = true;     # Allow hibernation (default: true)
  hibernateDelay = "2h";       # Suspend-then-hibernate after 2 hours (default: null)
};
```

**Example: Disable suspend/hibernate (desktop systems):**
```nix
hyprflake.system.power.sleep = {
  allowSuspend = false;
  allowHibernation = false;
};
```

**Example: Enable suspend-then-hibernate (laptops):**
```nix
hyprflake.system.power.sleep.hibernateDelay = "2h";
```

System will suspend normally, then automatically hibernate after 2 hours to preserve battery.

#### Logind Power Event Handling

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

**Example: Lock on lid close (desktops with lid switch):**
```nix
hyprflake.system.power.logind.handleLidSwitch = "lock";
```

#### Resume Commands

Execute commands after waking from suspend/hibernate:

```nix
hyprflake.system.power.resumeCommands = ''
  # Restart network manager
  systemctl restart NetworkManager

  # Fix audio after resume
  systemctl --user restart pipewire
'';
```

#### Real-World Example: Desktop System (qbert)

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

#### Real-World Example: Laptop System

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

## Development Status

### ✅ Completed

- [x] Basic flake structure with nixpkgs-based dependencies
- [x] Modular NixOS and Home Manager configurations
- [x] GPU-specific optimizations (AMD/NVIDIA/Intel)
- [x] Theme system with dconf integration
- [x] XDG portals and desktop integration
- [x] Essential Wayland packages and services
- [x] Helper functions for easy consumption
- [x] Plymouth boot splash with wallpaper integration
- [x] Waybar configuration with theming integration
- [x] Waybar auto-hide utility (enabled by default)
- [x] Hyprshell window switcher via Home Manager services.hyprshell
- [x] Application-specific theming (kitty, rofi, swaync, swayosd, wlogout)
- [x] Migration to nixpkgs (Hyprland and hyprshell from stable releases)
- [x] XDG autostart support via dex (enabled by default)
- [x] Shortcuts viewer with rofi/fzf (Super+? and Super+Shift+?)
- [x] Comprehensive power management system
  - [x] Configurable hypridle timeouts (lock, DPMS, suspend)
  - [x] Power profile support (power-profiles-daemon and TLP)
  - [x] Waybar power profile widget with click-to-cycle
  - [x] Thermal management (thermald for Intel CPUs)
  - [x] Sleep/hibernate control with suspend-then-hibernate
  - [x] Logind power event configuration
  - [x] Battery charge thresholds (TLP)
  - [x] Resume command hooks

### 🔄 Next Steps

- [ ] Add more theme packages (GTK themes, icon themes)
- [ ] Hyprpaper/wallpaper management
- [ ] Example configurations and documentation
- [ ] Testing framework for different GPU configurations

## Technical Notes

### Waybar Auto-Hide

The waybar-auto-hide utility provides automatic Waybar visibility management:

1. **Integration**: Enabled by default via `hyprflake.waybar-auto-hide.enable = true`
2. **Functionality**:
   - Monitors workspace state through Hyprland IPC
   - Automatically hides Waybar when workspace is empty
   - Reveals Waybar when cursor approaches top screen edge
3. **Requirements**:
   - Waybar IPC enabled (configured automatically in waybar module)
   - Launched via Hyprland `exec-once` (handled by module)
4. **Source**: [bashfulrobot/nixpkg-waybar-auto-hide](https://github.com/bashfulrobot/nixpkg-waybar-auto-hide)

### Hyprshell Window Switcher

The hyprshell integration provides native alt-tab window switching:

1. **Integration**: Always enabled automatically (no configuration needed)
2. **Functionality**:
   - Alt-tab window switching using the `Alt` modifier key
   - Filters windows by current monitor only
   - Does not switch workspaces
3. **Features Disabled**:
   - Launcher functionality disabled (using rofi instead)
   - Overview mode disabled
4. **Requirements**:
   - Uses `pkgs.hyprshell` from nixpkgs
   - Automatically configured via Home Manager `services.hyprshell`
   - Hyprland plugin built at runtime (version synced with nixpkgs Hyprland)
5. **Source**: [nixpkgs hyprshell package](https://search.nixos.org/packages?channel=unstable&query=hyprshell)

### Theme Propagation Flow

1. User sets `hyprflake.colorScheme` (e.g., "catppuccin-mocha")
2. Stylix applies the base16 color scheme system-wide
3. Plymouth auto-detects and matches the color scheme
   - Catppuccin variants use catppuccin-plymouth
   - Other schemes fall back to Circle HUD theme
4. NixOS dconf module applies themes via `programs.dconf.profiles.user.databases`
5. Home Manager dconf module applies via `dconf.settings`
6. Home Manager GTK module configures themes directly
7. Wallpaper is shared between Hyprland and Stylix

### GPU Configuration Logic

- Uses boolean flags instead of enum for flexibility
- Each GPU type has specific driver and environment variable configuration
- NVIDIA includes Wayland-specific workarounds and optimizations
- AMD enables initrd support for early KMS
- Intel enables GPU tools for debugging

### Module Dependencies

- All modules are optional with enable flags
- NixOS hyprland module enables core Hyprland functionality
- Other modules extend with specific features (caching, theming, etc.)
- Helper functions automatically include all necessary modules

## Commands for Development

```bash
# Check Nix syntax
statix check .

# Format Nix code
nixpkgs-fmt .

# Test flake evaluation
nix flake check

# Build development environment
nix develop
```

## Integration Points

This flake is designed to be consumed by other flakes that need Hyprland. It provides:

- Complete system-level configuration via NixOS modules
- User-level configuration via Home Manager modules
- Helper functions for common use cases
- Flexible theming that works with or without Stylix
- GPU optimization for different hardware configurations

The modular design allows consumers to pick and choose which features they need while maintaining consistency and avoiding duplication.

### Dependency Management for Consumers

**IMPORTANT:** When consuming hyprflake in your own flake, you **MUST** set up input follows to ensure version consistency across all dependencies.

Without follows, you may experience:
- Outdated nested dependencies even after updating hyprflake
- Duplicate packages increasing closure size
- Version conflicts between dependencies

Here's the required configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waybar-auto-hide = {
      url = "github:bashfulrobot/nixpkg-waybar-auto-hide";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprflake = {
      url = "github:bashfulrobot/hyprflake";
      # Follow all inputs to ensure version consistency
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        stylix.follows = "stylix";
        waybar-auto-hide.follows = "waybar-auto-hide";
      };
    };
  };
}
```

**Benefits of this approach:**
- Single source of truth for all package versions in your flake's lock file
- Reduced closure size (no duplicate dependencies)
- Guaranteed compatibility between hyprflake and its sub-dependencies
- Independent updates: update hyprflake without updating its transitive dependencies
- Simplified debugging: all versions controlled in one place

**Why nixpkgs instead of upstream flakes:**
- Hyprland and hyprshell are sourced from **nixpkgs** (not upstream flakes)
- Versions are managed by nixpkgs maintainers - stable, tested releases
- No binary cache configuration needed (nixpkgs is cached by default)
- Update with `nix flake update nixpkgs` like any other package

**For local development:** If you're developing hyprflake locally and consuming it from another flake, use path references with follows:
```nix
hyprflake = {
  url = "path:/home/user/dev/nix/hyprflake";
  inputs = {
    nixpkgs.follows = "nixpkgs";
    home-manager.follows = "home-manager";
    stylix.follows = "stylix";
    waybar-auto-hide.follows = "waybar-auto-hide";
  };
};
```

## Development Resources

### Project Organization

- Project documentation is in `extras/docs/`.
- Architectural decisions are in `extras/decisions/`.

### Upstream Documentation

- [Stylix Documentation](https://nix-community.github.io/stylix/configuration.html)
- [NixOS Hyprland Wiki](https://wiki.nixos.org/wiki/Hyprland)
- [Hyprland NixOS Wiki](https://wiki.hypr.land/Nix/Hyprland-on-NixOS/)