# Screenshot Module Implementation Plan

**Status:** Planning
**Phase:** 2 - Enhanced User Experience (P1)
**Priority:** High
**Effort:** Medium

---

## 🎯 Goals

Create a comprehensive, laptop-friendly screenshot workflow for Hyprland with:
- Multiple capture modes (region, screen, window)
- Clipboard-first workflow
- Annotation support with Stylix theming
- OCR text extraction
- Integration with existing Hyprflake components

---

## 📊 Analysis Summary

### Current State

**Ubuntu Development Machine:**
- ✅ satty (annotation tool)
- ✅ tesseract (OCR engine)
- ✅ wl-clipboard (copy/paste)
- ❌ grimblast (needs installation)
- ❌ grim/slurp (core tools)

**Old NixOS Setup (nixcfg):**
- 4 separate scripts (region, fullscreen, annotate, ocr)
- Grimblast-based capture
- Clipboard-first approach
- Satty for annotations
- Tesseract for OCR
- **Issue:** Used Print key (not available on laptops)

**Current Ansible/Cosmic Setup:**
- cosmic-screenshot + satty pipeline
- **Issue:** Cosmic-specific, won't work on Hyprland

---

## 🏗️ Architecture

### Module Structure

```
hyprflake/modules/desktop/screenshot/
├── default.nix              # Main module configuration
├── style.nix               # Satty Stylix theme integration
└── scripts/
    ├── screenshot-region.sh     # Interactive area selection
    ├── screenshot-screen.sh     # Full screen capture
    ├── screenshot-window.sh     # Active window capture
    ├── screenshot-annotate.sh   # Annotate last screenshot
    └── screenshot-ocr.sh        # OCR text extraction
```

### Dependencies

**System Packages:**
- `grim` - Core Wayland screenshot utility
- `grimblast` - Enhanced grim wrapper with better Hyprland integration
- `slurp` - Interactive region selector
- `satty` - Modern annotation tool (Rust-based)
- `tesseract` - OCR engine
- `wl-clipboard` - Wayland clipboard utilities
- `libnotify` - Desktop notifications

**Hyprflake Dependencies:**
- SwayNC (notifications)
- Stylix (theming)
- wl-clipboard already used by other modules

---

## ⌨️ Keybindings (Laptop-Friendly)

**Problem:** Laptops don't have dedicated Print Screen key

**Solution:** Use Super+Shift+S as base (familiar from Windows), with modifiers

| Keybind | Mode | Action |
|---------|------|--------|
| `Super + Shift + S` | **Region** | Select area → clipboard + save |
| `Super + Shift + F` | **Fullscreen** | Entire screen → clipboard + save |
| `Super + Shift + W` | **Window** | Active window → clipboard + save |
| `Super + Shift + A` | **Annotate** | Open last screenshot in satty |
| `Super + Shift + T` | **OCR** | Extract text from last screenshot |

**Rationale:**
- `Super+Shift+S` is the Windows screenshot shortcut (familiar)
- All grouped under `Super+Shift+[letter]` for consistency
- Mnemonic: **S**creenshot, **F**ullscreen, **W**indow, **A**nnotate, **T**ext
- Easy to reach on laptop keyboards
- No conflicts with existing Hyprland/Hyprflake bindings

**Alternative Consideration (if conflicts exist):**
- `Super + P` + modifier keys (P for Picture)
- `Super + Alt + [key]` combinations

---

## 📁 File Organization

### Screenshot Storage

**Primary Directory:** `~/Pictures/Screenshots/`
- Auto-created if doesn't exist
- Standard XDG Pictures location

**Filename Format:**
```
YYMMDD_HHhMMmSSs_<mode>.png

Examples:
241130_14h23m45s_region.png
241130_14h24m12s_fullscreen.png
241130_14h25m03s_window.png
```

**Annotated Screenshots:**
- Saved by satty based on user action
- Default: `~/Screenshots/` (satty config)
- Format: `YYYY-MM-DD_HH-MM-SS.png`

**Temp Files:**
- `/tmp/screenshot-<timestamp>.png`
- Auto-cleaned after 5 seconds

---

## 🎨 Satty Configuration

### Stylix Theme Integration

**Color Palette:** (style.nix)
- Use Stylix base16 colors for annotation tools
- Automatically adapts to theme changes
- Consistent with desktop color scheme

**Configuration (`~/.config/satty/config.toml`):**

```toml
[general]
fullscreen = true
early-exit = false
corner-roundness = 12
initial-tool = "arrow"
copy-command = "wl-copy"
annotation-size-factor = 2
output-filename = "~/Screenshots/%Y-%m-%d_%H-%M-%S.png"
save-after-copy = false
default-hide-toolbars = false
primary-highlighter = "block"
disable-notifications = false

[font]
family = "<Stylix sansSerif font>"
style = "Bold"

[color-palette]
palette = [
    "#<base0C>",  # Cyan
    "#<base08>",  # Red
    "#<base09>",  # Orange
    "#<base0D>",  # Blue
    "#<base0B>",  # Green
    "#<base0E>",  # Magenta
]

custom = [
    "#<base0C>", "#<base08>", "#<base09>", "#<base0A>",
    "#<base0B>", "#<base0E>", "#<base0D>", "#<base0F>",
]
```

---

## 🔧 Script Implementations

### 1. screenshot-region.sh

**Purpose:** Interactive area selection

**Workflow:**
1. User presses `Super+Shift+S`
2. `grimblast save area` launches (uses slurp for selection)
3. Screenshot saved to temp file
4. Copied to clipboard via `wl-copy`
5. Saved to `~/Pictures/Screenshots/` with timestamp
6. Notification sent via `notify-send`
7. Temp file cleaned after 5s

**Key Features:**
- Clipboard-first (primary workflow)
- Also saves to disk (backup)
- Rich notifications with preview thumbnail
- Error handling and validation

---

### 2. screenshot-screen.sh

**Purpose:** Capture entire screen

**Workflow:**
1. User presses `Super+Shift+F`
2. `grimblast save screen` captures full display
3. Same clipboard + save + notify workflow as region

**Notes:**
- No user interaction required
- Instant capture
- Works on multi-monitor setups (captures all)

---

### 3. screenshot-window.sh

**Purpose:** Capture active window

**Workflow:**
1. User presses `Super+Shift+W`
2. `grimblast save active` captures focused window
3. Same clipboard + save + notify workflow

**Enhancement over old setup:**
- This mode was missing in nixcfg
- Useful for documenting specific apps

---

### 4. screenshot-annotate.sh

**Purpose:** Annotate the most recent screenshot

**Workflow:**
1. User presses `Super+Shift+A`
2. Script finds most recent PNG in `~/Pictures/Screenshots/`
3. Opens in `satty` with arrow tool selected
4. User annotates and chooses action:
   - Copy to clipboard (wl-copy)
   - Save to `~/Screenshots/` (satty handles naming)
   - Both
5. Original screenshot remains untouched

**Key Features:**
- Works on any screenshot (not just ones from our scripts)
- Satty handles save/copy logic
- Stylix-themed color palette

---

### 5. screenshot-ocr.sh

**Purpose:** Extract text from last screenshot using OCR

**Workflow:**
1. User presses `Super+Shift+T`
2. Script finds most recent PNG in `~/Pictures/Screenshots/`
3. Runs `tesseract` OCR on image
4. Extracted text copied to clipboard
5. Notification shows preview of extracted text
6. Temp OCR output cleaned

**Use Cases:**
- Extract text from error messages
- Copy URLs from screenshots
- Grab code snippets from images
- Extract table data

**Tech Details:**
- Uses `tesseract` with English language model
- Output saved to `/tmp/screenshot-ocr/output.txt`
- Full text copied via `wl-copy`
- Works best with clear, high-contrast text

---

## 🔔 Notification System

### Integration with SwayNC

All screenshot scripts use `notify-send` which integrates with SwayNC:

**Notification Format:**

**Success:**
```
Title: "Region Screenshot" / "Fullscreen Screenshot" / etc.
Body: "📋 Copied to clipboard
       💾 Saved: 241130_14h23m45s_region.png"
Icon: Thumbnail of the screenshot
Timeout: 5000ms
```

**OCR Success:**
```
Title: "OCR Complete"
Body: "📋 Extracted text copied to clipboard
       Preview: <first 100 chars of text>"
Icon: Text icon
Timeout: 5000ms
```

**Error:**
```
Title: "Screenshot Failed" / "OCR Failed"
Body: Error details
Urgency: critical
```

---

## 📦 Package Requirements

### NixOS Packages

```nix
environment.systemPackages = with pkgs; [
  grim          # Core screenshot tool
  grimblast     # Enhanced wrapper
  slurp         # Region selector
  satty         # Annotation tool
  tesseract     # OCR engine
  wl-clipboard  # Clipboard ops
  libnotify     # Notifications
];
```

### Script Packaging

```nix
screenshotScripts = with pkgs; [
  (writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = [ grimblast wl-clipboard libnotify coreutils ];
    text = builtins.readFile ./scripts/screenshot-region.sh;
  })
  # ... other scripts
];
```

**Benefits of `writeShellApplication`:**
- Automatic runtime dependency injection
- PATH management
- Shellcheck validation
- Consistent error handling

---

## 🎛️ Hyprland Integration

### Keybind Configuration

**Location:** `modules/desktop/hyprland/default.nix`

```nix
bind = [
  # Screenshot workflows
  "$mod SHIFT, S, exec, screenshot-region"
  "$mod SHIFT, F, exec, screenshot-screen"
  "$mod SHIFT, W, exec, screenshot-window"
  "$mod SHIFT, A, exec, screenshot-annotate"
  "$mod SHIFT, T, exec, screenshot-ocr"
];
```

### Exec-Once

No exec-once needed - all scripts are on-demand.

---

## 🧩 Stylix Integration

### Color Palette Mapping

**satty style.nix pattern:**

```nix
{ config }: ''
  [color-palette]
  palette = [
      "@blue",     # base0D - Primary accent
      "@red",      # base08 - Errors/highlights
      "@yellow",   # base0A - Warnings
      "@green",    # base0B - Success
      "@pink",     # base0E - Special
      "@surface1", # base02 - Neutral
  ]

  custom = [
      "@blue", "@red", "@yellow", "@green",
      "@pink", "@surface0", "@surface1", "@surface2"
  ]
''
```

**Font Configuration:**

```nix
[font]
family = "${config.stylix.fonts.sansSerif.name}"
style = "Bold"
```

---

## 📋 Implementation Checklist

### Phase 1: Core Module Setup
- [ ] Create `modules/desktop/screenshot/` directory
- [ ] Create `default.nix` with module options
- [ ] Define package dependencies
- [ ] Create scripts directory
- [ ] Add module to `modules/default.nix` imports

### Phase 2: Script Development
- [ ] Implement `screenshot-region.sh`
- [ ] Implement `screenshot-screen.sh`
- [ ] Implement `screenshot-window.sh`
- [ ] Implement `screenshot-annotate.sh`
- [ ] Implement `screenshot-ocr.sh`
- [ ] Package scripts with `writeShellApplication`

### Phase 3: Satty Configuration
- [ ] Create `style.nix` for Stylix integration
- [ ] Configure satty.toml with Stylix colors
- [ ] Configure satty.toml with Stylix fonts
- [ ] Set up output directories

### Phase 4: Hyprland Integration
- [ ] Add keybindings to Hyprland config
- [ ] Test keybind conflicts
- [ ] Verify all modes work correctly

### Phase 5: Testing & Documentation
- [ ] Test each screenshot mode
- [ ] Test annotation workflow
- [ ] Test OCR workflow
- [ ] Test multi-monitor scenarios
- [ ] Test error handling (no screenshot found, etc.)
- [ ] Update assessment.md
- [ ] Add README.md to screenshot module

---

## 🔍 Testing Strategy

### Manual Testing Scenarios

1. **Basic Capture:**
   - [ ] Region selection works
   - [ ] Fullscreen capture works
   - [ ] Window capture works
   - [ ] Files saved to correct location
   - [ ] Clipboard contains image data

2. **Annotation:**
   - [ ] Opens most recent screenshot
   - [ ] Satty uses correct theme colors
   - [ ] Copy to clipboard works
   - [ ] Save to file works
   - [ ] Can annotate multiple times

3. **OCR:**
   - [ ] Extracts text from clear screenshots
   - [ ] Handles no text gracefully
   - [ ] Clipboard contains extracted text
   - [ ] Notifications show preview

4. **Edge Cases:**
   - [ ] No screenshots exist (annotate/ocr)
   - [ ] Screenshot directory doesn't exist (auto-create)
   - [ ] Cancel region selection (no error)
   - [ ] Multi-monitor setup (correct capture)
   - [ ] Permission issues (show error)

5. **Integration:**
   - [ ] Notifications appear in SwayNC
   - [ ] Keybindings don't conflict
   - [ ] Works with different Stylix themes
   - [ ] Scripts available in PATH

---

## 🚀 Future Enhancements (Post-Phase 2)

**Phase 3 (P2) Potential:**
- Video recording integration (wf-recorder)
- Screenshot history viewer
- Cloud upload integration (imgur, etc.)
- Customizable keybindings via options
- Per-monitor screenshot selection
- Delay timer for screenshots
- Screen recording with audio

**Not Planned (out of scope):**
- GIF recording (use separate tool)
- Video editing (satty is image-only)
- Advanced OCR (multiple languages)

---

## 🎨 User Experience Goals

### Clipboard-First Workflow
Most users paste screenshots immediately (Discord, Slack, etc.)
- **Clipboard is primary target**
- File saving is secondary/backup
- No interruption to user flow

### Minimal Friction
- One keypress = instant capture
- No dialogs or confirmations
- Fast feedback via notifications
- Quick access to annotation

### Discoverability
- Logical keybind grouping (Super+Shift+[letter])
- Mnemonic letter choices
- Consistent notification format
- Clear error messages

---

## 📝 Module Options Design

```nix
options.hyprflake.screenshot = {
  enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable screenshot workflow";
  };

  saveDirectory = lib.mkOption {
    type = lib.types.str;
    default = "~/Pictures/Screenshots";
    description = "Directory for saving screenshots";
  };

  annotationDirectory = lib.mkOption {
    type = lib.types.str;
    default = "~/Screenshots";
    description = "Directory for annotated screenshots (satty)";
  };

  # Future: Keybind customization options
};
```

---

## 🔗 References

**Old Implementation:**
- `nixcfg-main/.../programs/screenshot/default.nix`
- Scripts in `nixcfg-main/.../programs/screenshot/scripts/`
- Satty config in `nixcfg-main/.../apps/satty/default.nix`

**Current Ansible:**
- `~/dev/iac/desktoperator/roles/apps/screenshot/`

**External Documentation:**
- [grimblast GitHub](https://github.com/hyprwm/contrib)
- [satty GitHub](https://github.com/gabm/satty)
- [tesseract docs](https://github.com/tesseract-ocr/tesseract)

---

## ✅ Success Criteria

**Phase 2 Complete When:**
1. All 5 screenshot modes work flawlessly
2. Satty integrates with Stylix theming
3. OCR extracts text reliably
4. Keybindings are intuitive and conflict-free
5. Notifications provide clear feedback
6. Code follows Hyprflake patterns (Stylix helpers, mkStyle, etc.)
7. All statix checks pass
8. Assessment.md updated to mark Screenshot Suite as COMPLETE

---

**Status:** Ready for implementation
**Next Step:** Create `modules/desktop/screenshot/default.nix` and begin Phase 1
