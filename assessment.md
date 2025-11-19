# Hyprflake Enhancement Assessment

**Assessment Date:** 2025-11-18
**Source Analysis:** nixcfg Hyprland Configuration
**Target:** hyprflake Improvement Roadmap

---

## 🎯 Executive Summary

The old nixcfg has a **production-grade, battle-tested Hyprland ecosystem** with extensive features that hyprflake currently lacks. The current hyprflake is minimal and foundational - perfect for expansion. I've identified **critical missing features**, **nice-to-have enhancements**, and features to skip.

---

## 🔴 CRITICAL MISSING FEATURES

These are essential for a complete Hyprland desktop experience:

### 1. **GNOME Keyring Integration** ⭐⭐⭐⭐⭐
**Status:** ✅ COMPLETE - Implemented in `modules/system/keyring.nix`
**Why Critical:** Without this, users have no secure credential storage, SSH keys won't persist, and browser password management breaks.

**What nixcfg has:**
- Systemd services for `gnome-keyring-ssh` and `gnome-keyring-secrets` components
- PAM integration for auto-unlock on login
- Security wrappers with proper capabilities (`cap_ipc_lock=ep`)
- Environment variables properly configured (`SSH_AUTH_SOCK`, `GNOME_KEYRING_CONTROL`)
- Script to auto-load SSH keys (`ssh-add-keys`)

**Recommendation:** Add as a module `modules/system/keyring.nix` with:
```nix
- systemd.user.services for ssh/secrets components
- security.pam.services.*.enableGnomeKeyring
- security.wrappers.gnome-keyring-daemon
- Packages: gnome-keyring, gcr_4, libsecret, seahorse, pinentry-all
```

---

### 2. **Notification System (SwayNC)** ⭐⭐⭐⭐⭐
**Status:** ✅ COMPLETE - Full implementation in `modules/desktop/swaync/` with enhanced Stylix theming
**Why Critical:** Users need visual notifications for system events, applications, media controls.

**Implementation Details:**
- Full SwayNC configuration with Stylix base16 color integration (`@base00-@base0F`)
- Enhanced CSS styling with proper borders (2px outline, 6px left accent), drop shadows
- Notification widgets: title, DND toggle (styled switch), MPRIS (media controls), notification management
- Waybar integration for notification counter with custom icon states
- Proper urgency level styling (low/normal/critical with colored left borders)
- Polished action buttons, close buttons, scrollbars

**Visual Enhancements:**
- Consistent 8px border radius matching window corners
- Subtle box shadows for depth (`0 2px 8px`, `-6px 0 12px` on left)
- Smooth 200ms transitions on interactive elements
- Themed DND toggle switch with proper checked/unchecked states

---

### 3. **SwayOSD (On-Screen Display)** ⭐⭐⭐⭐
**Status:** ✅ COMPLETE - Implemented in `modules/desktop/swayosd/`
**Why Critical:** Without visual feedback, users don't know if volume/brightness changes worked.

**Implementation Details:**
- Full Stylix base16 color integration with consistent styling pattern
- LibInput backend systemd service for automatic caps/num/scroll lock detection
- Udev rules for brightness control without root
- User added to `video` and `input` groups (requires `hyprflake.user.username`)
- Visual styling: 8px border radius (matching window corners), accent-colored border and icons (`base0D`), styled progressbar with background
- Server config: `show_percentage = true`, `max_volume = 100`
- Position: 0.85 top margin (near bottom of screen for less intrusion)

**Visual Consistency:**
- Same border radius as Hyprland windows (8px) and swaync containers
- Progress bar with visible track (`base01`) and accent fill (`base0D`)
- Monospace font from Stylix with bold text for readability

---

### 4. **Idle Management (hypridle)** ⭐⭐⭐⭐
**Status:** ✅ COMPLETE - Implemented in `modules/desktop/hypridle/`
**Why Critical:** Laptops will never lock/suspend automatically, draining battery and exposing security risks.

**What nixcfg has:**
```nix
services.hypridle = {
  enable = true;
  settings = {
    general = {
      ignore_dbus_inhibit = false;
      lock_cmd = "pidof hyprlock || hyprlock";
      before_sleep_cmd = "loginctl lock-session";
      after_sleep_cmd = "hyprctl dispatch dpms on";
    };
    listener = [
      { timeout = 300; on-timeout = "loginctl lock-session"; }  # 5 min
      { timeout = 360; on-timeout = "hyprctl dispatch dpms off"; on-resume = "hyprctl dispatch dpms on"; }  # 6 min
      { timeout = 600; on-timeout = "systemctl suspend"; }  # 10 min
    ];
  };
};
```

**Recommendation:** Add `modules/home/hypridle/default.nix` with configurable timeouts.

---

### 5. **Screen Lock (hyprlock)** ⭐⭐⭐⭐
**Status:** ✅ COMPLETE - Implemented in `modules/desktop/hyprlock/` with Stylix integration
**Why Critical:** Hypridle triggers lock but nothing happens. Security hole.

**What nixcfg has:**
```nix
programs.hyprlock = {
  enable = true;
  settings = {
    background = [ { blur_size = 3; blur_passes = 2; } ];
    input-field = [ { size = "250, 50"; outline_thickness = 3; placeholder_text = "Password..."; } ];
    label = [
      { text = "$TIME"; font_size = 64; }
      { text = "Hello <span>$USER!</span>"; }
      { text = "Current Layout : $LAYOUT"; }
    ];
  };
};
```

**Recommendation:** Add `modules/home/hyprlock/default.nix` with stylix color/font integration.

---

### 6. **Logout Menu (wlogout)** ⭐⭐⭐⭐
**Status:** Keybind exists but no configuration
**Why Critical:** Users can't gracefully logout/shutdown/reboot from desktop.

**What nixcfg has:**
- Wlogout configured with 4 actions: logout, shutdown, suspend, reboot
- Custom CSS styling via stylix-theme
- Icon integration
- Keybindings to each action (e, s, u, r)

**Recommendation:** Add `modules/home/wlogout/default.nix` with stylix theming.

---

### 7. **Application Launcher (Rofi)** ⭐⭐⭐⭐⭐
**Status:** Mentioned in keybinds but not configured
**Why Critical:** Users can't launch apps without terminal.

**What nixcfg has:**
```nix
programs.rofi = {
  enable = true;
  package = pkgs.rofi-wayland;
  plugins = [rofi-emoji-wayland rofi-games];
};
# Custom config files for different use cases:
# - config-music.rasi
# - config-long.rasi
# - config-wallpaper.rasi
# - launchers/colors/assets/resolution directories
```

**Recommendation:** Add `modules/home/rofi/default.nix` with basic config and optional plugin support.

---

## 🟡 HIGH-VALUE ENHANCEMENTS

These significantly improve the user experience:

### 8. **Screenshot Workflow** ⭐⭐⭐⭐
**Status:** Basic grimblast in hyprflake
**What to Add:**
- Clipboard-first workflow (auto-copy to clipboard)
- Multiple scripts: `screenshot-region`, `screenshot-fullscreen`, `screenshot-annotate`, `screenshot-ocr`
- Satty integration for annotations
- OCR via tesseract
- Notification feedback via SwayOSD

**Recommendation:** Add `modules/desktop/screenshot/default.nix` with full script suite.

---

### 9. **Window Dimming (hyprdim)** ⭐⭐⭐
**Status:** MISSING
**Why Useful:** Improves focus by dimming inactive windows.

```nix
systemd.user.services.hyprdim = {
  description = "Hyprdim - Window dimming for Hyprland";
  ExecStart = "${pkgs.hyprdim}/bin/hyprdim --strength 0.5 --duration 600 --fade 5 --dialog-dim 0.8";
};
```

**Recommendation:** Add as optional service in `modules/desktop/hyprdim/default.nix`.

---

### 10. **Enhanced Waybar Configuration** ⭐⭐⭐⭐
**Status:** ✅ ENHANCED - Polished implementation with advanced styling
**What's Implemented:**
- **Network module** replacing nm-applet with proper icon states (wifi/ethernet/disconnected)
- **System info drawer** - collapsible module group with gear icon trigger
- **Workspace state differentiation** - distinct styling for active, occupied, urgent states
- **Notification integration** - SwayNC widget with DND state indicators
- **Idle inhibitor** - visual toggle for preventing screen sleep
- **MPRIS submap** - media controls available via Hyprland submap
- **Comprehensive CSS** with proper Stylix base16 color integration

**Visual Polish:**
- 85% transparency with subtle background blur (`rgba(30, 30, 46, 0.85)`)
- Refined height (28px) with 4px bottom border radius
- Enhanced workspace button states with smooth 0.2s transitions
- Proper color coding: clock (@base0A), pulseaudio (@base0E), bluetooth (@base0D), network (@base0C)
- Themed battery states (critical/charging with distinct colors)

**Potential Future Enhancements:**
- **Language indicator** for keyboard layouts
- **Temperature monitoring**
- **Custom cava audio visualizer**
- **GPU info module**
- **Advanced battery actions** (power profile switcher via rofi)
- **Enhanced pulseaudio** right-click menu with audio device switcher

---

### 11. **Comprehensive Keybinding System** ⭐⭐⭐⭐
**Current:** Basic keybinds
**Enhancements from nixcfg:**
- **Submap system** for mode-based keybinds (resize mode, explore mode, special workspaces)
- **Submap-hints** - visual rofi hints showing available keybinds in each mode
- **Function key bindings** for custom swayosd indicators (F1-F4, Shift+F1-F2)
- **Night mode** toggle (hyprsunset for blue light filter)
- **Autoclicker** toggle
- **Espanso shortcuts menu**
- **Help menus** - rofi-based keybind reference
- **Media key mappings** for laptop function keys
- **Game mode toggle** (disables hypr effects for performance)

**Recommendation:** Optionally add submap system and helper scripts.

---

### 12. **Screen Recording (wf-recorder)** ⭐⭐⭐
**Status:** MISSING
**Scripts:**
- `wf-recorder-toggle` - fullscreen recording
- `wf-recorder-area` - area selection recording

**Recommendation:** Add `modules/desktop/wf-recorder/default.nix`.

---

### 13. **Advanced Window Rules** ⭐⭐⭐⭐
**Current:** Commented out/disabled
**What nixcfg has:**
- **Per-app opacity rules** (terminal, VSCode, browsers, Steam, Spotify, etc.)
- **Game detection** via tags (`tag +games, content:game`)
- **Game optimizations** (syncfullscreen, noborder, noshadow, noblur, noanim)
- **Special workspace assignments** (Spotify, 1Password)
- **Float rules** for specific app classes
- **Layer rules** for rofi blur

**Recommendation:** Uncomment and enhance windowrule section in hyprland config.

---

### 14. **Scripts & Helper Utilities** ⭐⭐⭐
**What nixcfg has:**
```bash
- batterynotify.sh - battery level notifications
- dontkillsteam.sh - prevent accidentally killing Steam
- ClipManager.sh - clipboard history manager
- rofi-launcher (for drun, emoji, games, window switcher)
- keyboardswitch.sh - change keyboard layout
- gamemode.sh - toggle gamemode
- rebuild.sh - NixOS rebuild from terminal
- submap-hints.sh - visual keybind hints
```

**Recommendation:** Add essential scripts as optional modules.

---

### 15. **Hyprshell Integration** ⭐⭐⭐
**Status:** MISSING
**What it provides:** Alt+Tab window switcher with modern UI

```nix
imports = [ inputs.hyprshell.homeModules.hyprshell ];
programs.hyprshell = {
  enable = true;
  settings.windows = {
    enable = true;
    switch = { enable = true; modifier = "alt"; };
  };
};
```

**Recommendation:** Add as optional module with flake input.

---

### 16. **Stylix Theme Library Integration** ⭐⭐⭐⭐
**Status:** ✅ COMPLETE - `lib/stylix-helpers.nix` implemented and working
**What's Implemented:**
- `mkStyle` function for consistent CSS generation from Nix files
- Automatic pattern: `stylePath` → `import { inherit config; }` → string interpolation
- Used consistently across all styled modules (swaync, waybar, hyprlock, hypridle)
- Proper integration with Stylix's base16 color system (`@base00-@base0F`)
- Font variable access via `config.stylix.fonts.*`

**Pattern Established:**
```nix
# In module:
style = stylix.mkStyle ./style.nix;

# In style.nix:
{ config }: ''
  .element {
    background: @base00;
    color: @base05;
    font-family: "${config.stylix.fonts.monospace.name}";
  }
''
```

This provides the same functionality as nixcfg's `buildTheme.build` but leverages Stylix's existing color variable system.

---

### 17. **Enhanced Animations & Visual Effects** ⭐⭐⭐
**Current:** Basic animations
**What nixcfg adds:**
- Multiple bezier curves (md3_standard, md3_decel, fluent_decel, easeOutExpo, etc.)
- Fine-tuned animation timings per element type
- Special workspace animations different from regular workspaces
- Window pop-in effects

**Recommendation:** Add as advanced animation presets option.

---

## 🔵 NICE-TO-HAVE FEATURES

### 18. **Dunst Alternative Notification Daemon** ⭐⭐
**Note:** nixcfg has both dunst and swaync. SwayNC is modern and Wayland-native, so dunst is redundant.
**Recommendation:** Skip - use SwayNC instead.

---

### 19. **Account Service User Avatar** ⭐⭐
**What nixcfg does:**
```nix
system.activationScripts.script.text = ''
  mkdir -p /var/lib/AccountsService/{icons,users}
  cp ${./.face} /var/lib/AccountsService/icons/${username}
  # Sets user avatar for display manager
'';
```

**Recommendation:** Add as optional display manager enhancement.

---

### 20. **Icon Cache Updates** ⭐⭐
**What nixcfg does:** Updates GTK icon caches on activation for notification icons.
**Recommendation:** Add as system activation script if notification icons aren't showing.

---

### 21. **Swaylock** ⭐
**Status:** nixcfg has it but hyprlock is better for Hyprland
**Recommendation:** Skip - hyprlock is the modern Hyprland-native solution.

---

### 22. **UWSM Support** ⭐⭐⭐
**Status:** Both have it, but nixcfg has more detailed handling
**Current hyprflake:** `withUWSM = false;`
**Recommendation:** Keep current approach, document UWSM benefits for users on Hyprland 0.34+.

---

## ⚠️ FEATURES TO SKIP OR BE CAUTIOUS ABOUT

### 23. **Display Manager in Hyprland Module** ❌
**Issue:** nixcfg has display manager config (GDM) in the Hyprland module.
**Why Skip:** Hyprflake correctly separates this into `modules/desktop/display-manager/default.nix`.
**Recommendation:** Keep separation - display manager is not Hyprland-specific.

---

### 24. **Hardcoded Paths & User-Specific Config** ❌
**Issue:** nixcfg has hardcoded paths like `~/dev/nix/nixcfg`, specific browser choices, terminal choices.
**Recommendation:** Hyprflake should stay generic - let consumers choose apps.

---

### 25. **Multiple QT Platform Theme Conflicts** ❌
**Issue:** nixcfg sets `QT_QPA_PLATFORMTHEME` to both "gnome" and "qt6ct" in different places.
**Recommendation:** Hyprflake correctly uses `lib.mkDefault "qt5ct"` per Hyprland wiki recommendation.

---

## 📊 PRIORITY MATRIX

| Priority | Feature | Effort | Impact | Status |
|----------|---------|--------|--------|--------|
| ✅ P0 | GNOME Keyring | Medium | Critical | COMPLETE |
| ✅ P0 | SwayNC | Medium | Critical | COMPLETE |
| ✅ P0 | hypridle | Low | Critical | COMPLETE |
| ✅ P0 | hyprlock | Low | Critical | COMPLETE |
| 🔴 P0 | wlogout | Low | Critical | TODO |
| 🔴 P0 | Rofi config | Low | Critical | TODO |
| ✅ P0 | SwayOSD | Medium | Critical | COMPLETE |
| 🟡 P1 | Screenshot suite | Medium | High | TODO |
| ✅ P1 | Enhanced waybar | High | High | ENHANCED* |
| 🟡 P1 | Window rules | Low | High | TODO |
| 🟡 P1 | Keybind system | Medium | High | TODO |
| ✅ P1 | Stylix theme lib | Medium | High | COMPLETE |
| 🟢 P2 | hyprdim | Low | Medium | TODO |
| 🟢 P2 | wf-recorder | Low | Medium | TODO |
| 🟢 P2 | Helper scripts | Medium | Medium | TODO |
| 🟢 P2 | Hyprshell | Low | Medium | TODO |
| 🟢 P2 | Advanced animations | Low | Medium | TODO |

*Enhanced waybar has network module, transparency, workspace states, system drawer - advanced modules (temp, cava, GPU) remain as future enhancements

---

## 🎯 RECOMMENDED IMPLEMENTATION PLAN

### Phase 1: Critical Desktop Functionality (P0)
1. ✅ ~~Add GNOME Keyring module~~ **COMPLETE** - `modules/system/keyring/`
2. ✅ ~~Add SwayNC notification center~~ **COMPLETE** - `modules/desktop/swaync/` with enhanced styling
3. ✅ ~~Add hypridle idle management~~ **COMPLETE** - `modules/desktop/hypridle/`
4. ✅ ~~Add hyprlock screen locker~~ **COMPLETE** - `modules/desktop/hyprlock/` with Stylix integration
5. ⏳ Add wlogout logout menu - keybind exists, needs configuration
6. ⏳ Add Rofi application launcher - mentioned in keybinds, needs full config
7. ✅ ~~Add SwayOSD on-screen display~~ **COMPLETE** - `modules/desktop/swayosd/` with Stylix theming, libinput backend

**Progress:** 5/7 complete (71%)

**Recent Enhancements (Phase 1 Polish):**
- SwayNC: Enhanced borders (6px left accent), drop shadows, proper DND toggle styling
- Waybar: Network module integration, 85% transparency, workspace state differentiation, refined height (28px) with bottom radius
- Font system: Verified Nerd Font support for waybar icons (Iosevka Nerd Font default)
- Stylix helpers: Established consistent `mkStyle` pattern across all modules

**Result:** Fully functional, secure desktop environment with polished visual presentation.

---

### Phase 2: Enhanced User Experience (P1)
1. ✅ ~~Create stylix-helpers library for theme consistency~~ **COMPLETE** - `lib/stylix-helpers.nix`
2. ✅ ~~Enhance waybar with advanced modules~~ **ENHANCED** - network, drawer, transparency, workspace states
3. ⏳ Add screenshot workflow with OCR
4. ⏳ Implement comprehensive keybind system with submaps
5. ⏳ Enable and expand window rules

**Progress:** 2/5 complete (40%)

**Next Steps:**
- Screenshot suite with grimblast, satty annotations, tesseract OCR
- Submap system for mode-based keybinds (resize, explore, special workspaces)
- Window rules for per-app opacity, game optimizations, float rules

**Result:** Production-quality desktop with advanced features.

---

### Phase 3: Polish & Extras (P2)
1. Add hyprdim window dimming
2. Add wf-recorder screen recording
3. Add helper scripts (battery notify, clipboard manager, etc.)
4. Add hyprshell window switcher
5. Add advanced animation presets
6. Add icon cache activation scripts

**Result:** Feature-complete Hyprland environment matching or exceeding nixcfg.

---

## 🏗️ ARCHITECTURAL RECOMMENDATIONS

### Module Structure Pattern
Follow nixcfg's excellent pattern:
```
modules/
├── system/          # NixOS-level config
│   ├── keyring.nix
│   └── ...
├── desktop/         # Desktop environment
│   ├── swaync/
│   │   ├── default.nix
│   │   └── style.css
│   ├── swayosd/
│   ├── hypridle/
│   └── ...
└── home/            # Home Manager config
    ├── hyprlock/
    ├── rofi/
    └── ...
```

### Stylix Integration
Create `lib/stylix-helpers.nix`:
```nix
{
  mkStyle = file: buildTheme.build {
    inherit (config.lib.stylix) colors;
    inherit (config.stylix) fonts;
    file = builtins.readFile file;
  };
}
```

Use across all themed modules.

### Configuration Options Pattern
Follow nixcfg pattern for user customization:
```nix
options = {
  desktops.hyprland.swayosd = {
    enable = lib.mkOption { type = lib.types.bool; default = true; };
    showPercentage = lib.mkOption { type = lib.types.bool; default = true; };
    maxVolume = lib.mkOption { type = lib.types.int; default = 100; };
  };
};
```

### Script Management
Use `writeShellScriptBin` pattern:
```nix
screenshotScripts = with pkgs; [
  (writeShellScriptBin "screenshot-region" (builtins.readFile ./scripts/screenshot-region.sh))
  (writeShellScriptBin "screenshot-fullscreen" (builtins.readFile ./scripts/screenshot-fullscreen.sh))
];

environment.systemPackages = screenshotScripts;
```

---

## 📝 SUMMARY

The old nixcfg is a **goldmine of production-tested Hyprland configuration**. It demonstrates:

✅ **What works:** Comprehensive keyring setup, excellent notification system, robust idle/lock management
✅ **Best practices:** Module separation, stylix integration, script management
✅ **Real-world polish:** Helper scripts, visual feedback (swayosd), advanced window rules

Hyprflake is currently **minimal and foundational** - perfect for consumption but missing critical desktop features. By implementing the **P0 and P1 features**, hyprflake will become a **complete, production-ready Hyprland flake** that rivals or exceeds nixcfg while maintaining its clean, reusable architecture.

The modular approach of both projects aligns perfectly - hyprflake can adopt nixcfg's features while maintaining its focus on being a reusable, configurable flake rather than a personal dotfiles repo.

---

## 🎬 Next Steps

**Immediate Actions:**
1. Start with P0 features in order
2. Create stylix-helpers library as foundation
3. Port nixcfg module patterns to hyprflake structure
4. Test each module independently before integration
5. Document configuration options for consumers

**Long-term Goals:**
- Match nixcfg feature completeness
- Exceed nixcfg with better modularity
- Maintain clean separation of concerns
- Keep hyprflake generic and reusable
- Build comprehensive test suite
