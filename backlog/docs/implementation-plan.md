# Hyprflake Migration Implementation Plan

## Overview

This document outlines the systematic implementation order for migrating the comprehensive Hyprland configuration from the nixcfg reference to the hyprflake project.

## Task Organization by Priority

### Critical Priority (Foundation) - Implement First
These tasks provide the absolute foundation that everything else depends on:

1. **task-13: Migrate foundational Hyprland window manager settings**
   - **Dependencies**: None
   - **Blocks**: All other tasks (provides basic window manager functionality)
   - **Key components**: Basic Hyprland config, input settings, keybinds, workspaces

2. **task-14: Ensure Home Manager and Stylix integration**
   - **Dependencies**: task-13 (needs basic Hyprland to test theming)
   - **Blocks**: All UI tasks (provides theming foundation)
   - **Key components**: Home Manager structure, Stylix theming, dconf integration

### High Priority (Enhanced Foundation) - Implement Second
These tasks add advanced functionality to the foundation:

3. **task-1: Enhance core Hyprland module with privacy monitoring**
   - **Dependencies**: task-13, task-14 (builds on basic config and theming)
   - **Blocks**: All other tasks (provides enhanced Hyprland functionality)
   - **Key components**: Privacy monitoring, polkit, keyring integration

4. **task-6: Create essential scripts module**
   - **Dependencies**: task-1 (needs enhanced Hyprland config for script references)
   - **Blocks**: task-2, task-3, task-4 (scripts used by UI components)
   - **Key components**: Screenshot, clipboard, keybinds, system utilities

5. **task-2: Add Waybar program module**
   - **Dependencies**: task-1, task-6, task-14 (uses scripts, core config, and theming)
   - **Blocks**: task-4 (notifications integrate with waybar)
   - **Key components**: Status bar, system monitoring, custom widgets

### Medium Priority (User Experience) - Implement Second
These tasks build the user interface and experience layer:

4. **task-11: Add package dependencies to modules**
   - **Dependencies**: task-1, task-6 (knows what packages are needed)
   - **Blocks**: task-3, task-4, task-5, task-7 (provides required packages)
   - **Key components**: Wayland tools, audio/media, system packages

5. **task-3: Create Rofi launcher module**
   - **Dependencies**: task-6, task-11 (needs scripts and packages)
   - **Blocks**: None (standalone launcher)
   - **Key components**: Application launcher, themes, resolution configs

6. **task-4: Add notification system modules**
   - **Dependencies**: task-2, task-11 (integrates with waybar, needs packages)
   - **Blocks**: task-5, task-7 (notifications used by other components)
   - **Key components**: SwayNC, notification scripts, icons

7. **task-5: Implement lock screen and idle management**
   - **Dependencies**: task-4, task-11 (uses notifications, needs packages)
   - **Blocks**: None (security feature)
   - **Key components**: Hyprlock, hypridle, theming integration

8. **task-7: Add SwayOSD module**
   - **Dependencies**: task-4, task-11 (works with notifications, needs packages)
   - **Blocks**: None (OSD system)
   - **Key components**: Volume/brightness OSD, system monitoring

9. **task-10: Update flake structure and exports**
   - **Dependencies**: All module tasks (1,2,3,4,5,6,7,11)
   - **Blocks**: None (integration task)
   - **Key components**: Flake exports, helper functions

### Low Priority (Polish) - Implement Last
These tasks add finishing touches and visual assets:

10. **task-8: Create assets and icons structure**
    - **Dependencies**: Most UI tasks completed (2,3,4,7,9)
    - **Blocks**: None (assets can be added incrementally)
    - **Key components**: Custom icons, user face, visual assets

11. **task-9: Add wlogout power menu module**
    - **Dependencies**: task-8 (may use custom icons), task-11 (needs packages)
    - **Blocks**: None (power menu feature)
    - **Key components**: Logout interface, power options, styling

## Recommended Implementation Sequence

### Phase 0: Critical Foundation (Critical Priority)
```
task-13 → task-14
```
**Rationale**: Establish basic window manager functionality and theming foundation before anything else.

### Phase 1: Enhanced Foundation (High Priority)
```
task-1 → task-6 → task-2
```
**Rationale**: Add advanced Hyprland features, essential scripts, then build the primary UI (waybar).

### Phase 2: System Integration (Medium Priority)
```
task-11 → task-3 → task-4 → task-5 → task-7 → task-10
```
**Rationale**: Add required packages, then build user interface components in order of dependency, finish with flake integration.

### Phase 3: Polish (Low Priority)
```
task-8 → task-9
```
**Rationale**: Add visual assets and final UI components once core functionality is complete.

## Critical Path Dependencies

The critical path for a minimally functional desktop:
**task-13 → task-14 → task-1 → task-6 → task-2 → task-11 → task-10**

This provides:
- Basic Hyprland window manager functionality
- Theme and user configuration system
- Enhanced Hyprland with privacy monitoring
- Essential scripts for basic functionality
- Status bar for system interaction
- All required packages
- Proper flake integration

## Milestone Definitions

### Milestone 0: Foundation Desktop (After Phase 0)
- Basic Hyprland window manager functional
- Window management, workspaces, and input working
- Theming system functional (Home Manager + Stylix)
- **Deliverable**: Minimal functional Hyprland desktop with theming

### Milestone 1: Enhanced Desktop (After Phase 1)
- Privacy monitoring and advanced features active
- Essential scripts work (screenshot, clipboard, etc.)
- Waybar provides system status and controls
- **Deliverable**: Feature-rich desktop with monitoring

### Milestone 2: Complete Desktop (After Phase 2)
- Application launcher (Rofi) available
- Notifications working (SwayNC)
- Lock screen and idle management active
- OSD feedback for system changes
- All modules properly integrated in flake
- **Deliverable**: Feature-complete desktop environment

### Milestone 3: Polished Desktop (After Phase 3)
- Custom icons and visual assets in place
- Power menu for logout/shutdown options
- **Deliverable**: Production-ready desktop matching reference config

## Testing Strategy

After each phase, test the following:

**Phase 0 Testing**:
- Hyprland starts and basic window management works
- Can switch workspaces and move windows
- Input devices (keyboard, mouse, touchpad) function correctly
- Basic theming applied (GTK themes, cursors, icons)
- Home Manager configuration generates without errors

**Phase 1 Testing**:
- Privacy monitoring notifications appear
- Essential shortcuts work (screenshot, clipboard)
- Waybar displays and functions correctly
- Advanced Hyprland features working

**Phase 2 Testing**:
- All applications launch via Rofi
- Notifications appear and can be managed
- Lock screen activates and unlocks properly
- OSD shows for volume/brightness changes
- Flake can be consumed by other projects

**Phase 3 Testing**:
- All visual elements match reference config
- Power menu options work correctly
- System feels cohesive and polished

## Risk Mitigation

**High Risk**: task-1 (Core Hyprland module)
- **Mitigation**: Implement incrementally, test frequently
- **Fallback**: Revert to basic Hyprland if privacy monitoring fails

**Medium Risk**: task-10 (Flake integration)
- **Mitigation**: Test flake exports after each module addition
- **Fallback**: Manual module imports if helper functions fail

**Low Risk**: All other tasks are largely independent

This implementation plan ensures a systematic, dependency-aware approach to migrating the complete Hyprland desktop environment.