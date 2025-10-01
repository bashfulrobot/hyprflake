---
id: task-13
title: Migrate foundational Hyprland window manager settings
status: In Progress
assignee: [@claude]
created_date: '2025-10-01 03:32'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extract and migrate the core Hyprland window manager configuration from the reference config to hyprflake's Home Manager module. Focus on basic functionality without complex services or privacy monitoring - just the essential window manager settings needed for a functional desktop.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Basic Hyprland window manager configuration migrated to home-manager module
- [ ] #2 Input settings (keyboard, mouse, touchpad) working correctly
- [ ] #3 Window management keybinds functional (focus, move, resize, workspaces)
- [ ] #4 Basic animations and decorations applied
- [ ] #5 Workspace management working (switching, moving windows)
- [ ] #6 Essential environment variables set for Wayland/Hyprland
<!-- AC:END -->

## Implementation Plan

1. ✅ Analyze current hyprflake Home Manager hyprland module structure
2. ✅ Extract foundational settings from reference configuration
3. ✅ Migrate core Hyprland settings including:
   - Environment variables for proper Wayland operation
   - Input configuration (keyboard, mouse, touchpad)
   - General window management settings (gaps, borders, layout)
   - Window decorations (blur, rounding, shadows)
   - Animations with proper bezier curves
   - Miscellaneous settings (logo, swallow, etc.)
   - Gesture support for touchpads
   - Layout-specific settings (dwindle, master)
   - XWayland configuration
   - Comprehensive keybindings for window management
   - Monitor and workspace configuration
4. ⏳ Test basic functionality
5. ⏳ Verify all acceptance criteria are met

## Current Status

Successfully migrated comprehensive foundational Hyprland configuration including:
- **Environment Variables**: 20+ essential Wayland/theming variables
- **Input Settings**: Keyboard, mouse, touchpad, tablet configuration
- **Window Management**: Gaps, borders, layouts, decorations
- **Animations**: 8 bezier curves with smooth window/workspace transitions
- **Keybindings**: 40+ essential binds including workspace management
- **System Integration**: Systemd integration, cursor themes, GTK configuration
