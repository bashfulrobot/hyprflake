# Hyprflake Improvement Plan

## Context

Hyprflake is a NixOS module library flake providing a Hyprland desktop environment. After a thorough codebase review and Nix-specialist review, 6 improvements were identified that address real structural and quality issues. Ordered by impact.

---

## 1. Add CI quality checks workflow (Quick Win)

**Why:** The justfile already has `fmt`, `lint`, `check`, `eval` commands but nothing runs in CI. The only GitHub Actions workflow updates flake.lock. Broken modules, formatting drift, and dead code accumulate silently.

**What:** Create `.github/workflows/ci.yml` running on PRs and pushes to main:

- `nix fmt -- --check` (formatting)
- `nix run nixpkgs#statix -- check .` (linting)
- `nix run nixpkgs#deadnix -- --fail .` (dead code detection — NOT `-f` which modifies files)
- `nix flake check` (flake validity)

**Prerequisites:** Fix any existing `statix` / `deadnix` violations first so the workflow isn't red on merge. Run `statix check .` and `deadnix --fail .` locally and fix issues before adding CI.

**Files:** `.github/workflows/ci.yml` (new, ~30 lines)

---

## 2. Split monolithic options.nix into co-located options (High Impact)

**Why:** The 711-line `modules/options.nix` is a maintenance bottleneck. Adding/modifying a module requires editing two separate files. The NixOS convention is co-located options. 4 modules already do this correctly (autostart, autostart-d, system-actions, shortcuts-viewer).

**What:** Move option definitions to their implementing modules:

| options.nix section            | Lines   | Target module                                  |
| ------------------------------ | ------- | ---------------------------------------------- |
| `hyprflake.style.*`            | 10-265  | `modules/desktop/stylix/default.nix`           |
| `hyprflake.user.*`             | 268-297 | `modules/system/user/default.nix`              |
| `hyprflake.desktop.waybar.*`   | 302-317 | `modules/desktop/waybar-auto-hide/default.nix` |
| `hyprflake.desktop.keyboard.*` | 320-342 | `modules/desktop/hyprland/default.nix`         |
| `hyprflake.desktop.idle.*`     | 345-380 | `modules/desktop/hypridle/default.nix`         |
| `hyprflake.desktop.voxtype.*`  | 383-476 | `modules/desktop/voxtype/default.nix`          |
| `hyprflake.system.plymouth.*`  | 482-493 | `modules/system/plymouth/default.nix`          |
| `hyprflake.system.power.*`     | 496-707 | `modules/system/power/default.nix`             |

Then delete `modules/options.nix` and remove its import from `modules/default.nix`.

**Implementation notes:**

- Target modules must add `hyprflakeInputs` to their function args where options reference flake inputs (e.g., `stylix/default.nix` uses `hyprflakeInputs.apple-fonts.packages`, `voxtype/default.nix` uses `hyprflakeInputs.voxtype`)
- Target modules must add `lib` to their function args if not already present (needed for `mkOption`, type definitions)
- `hyprflake.desktop.keyboard.*` is consumed by both hyprland and display-manager — defining it in hyprland is fine (module system resolves globally) but worth a comment noting this
- Deletion of `options.nix` and all moves must happen in a single atomic commit — partial moves break evaluation

**Safety:** The NixOS module system resolves options globally after all imports — moving a definition between files has zero behavioral change.

---

## 3. Add `enable` options to all modules (High Impact)

**Why:** This is a module library — consumers should be able to disable components they don't want. Currently 14 modules are always-on with no toggle. A consumer who prefers alacritty over kitty, or dunst over swaync, is stuck.

**What:** Add `lib.mkEnableOption` (defaulting to `true`) to these 14 modules, wrapping their `config` block in `lib.mkIf cfg.enable`:

| Module          | Option                                     |
| --------------- | ------------------------------------------ |
| swaync          | `hyprflake.desktop.swaync.enable`          |
| swayosd         | `hyprflake.desktop.swayosd.enable`         |
| rofi            | `hyprflake.desktop.rofi.enable`            |
| rofimoji        | `hyprflake.desktop.rofimoji.enable`        |
| hyprlock        | `hyprflake.desktop.hyprlock.enable`        |
| hypridle        | `hyprflake.desktop.hypridle.enable`        |
| hyprshell       | `hyprflake.desktop.hyprshell.enable`       |
| waybar          | `hyprflake.desktop.waybar.enable`          |
| wlogout         | `hyprflake.desktop.wlogout.enable`         |
| wl-clip-persist | `hyprflake.desktop.wl-clip-persist.enable` |
| kitty           | `hyprflake.home.kitty.enable`              |
| gtk             | `hyprflake.home.gtk.enable`                |
| keyring         | `hyprflake.system.keyring.enable`          |
| display-manager | `hyprflake.desktop.displayManager.enable`  |

Each option defined locally in its module file. Default `true` preserves backward compatibility.

**Cross-module dependencies to document in option descriptions:**

- **swayosd**: Hyprland volume/brightness keybindings depend on `swayosd-client`. Disabling breaks media controls.
- **rofi**: Hyprland `$menu` variable uses `rofi`. Disabling breaks app launcher keybind.
- **kitty**: Hyprland `$term` variable uses `kitty`. Disabling breaks terminal keybind.
- **swaync**: Hyprland `$mainMod+N` keybind calls `swaync-client`. Fails silently if disabled.
- **display-manager**: Also sets `services.xserver.xkb` from keyboard options. Disabling loses keyboard layout propagation.

**Pattern:**

```nix
{ config, lib, ... }:
let cfg = config.hyprflake.desktop.swaync;
in {
  options.hyprflake.desktop.swaync.enable =
    lib.mkEnableOption "SwayNC notification daemon" // { default = true; };
  config = lib.mkIf cfg.enable { /* existing body */ };
}
```

---

## 4. Fix commented-out Hyprland window rules (Quick Win)

**Why:** Lines 533-547 of `modules/desktop/hyprland/default.nix` have useful window rules disabled with a TODO. These provide opacity rules and float/pin rules for common apps.

**What:** Uncomment and update to current `windowrulev2` syntax. The root cause of breakage: these rules are inside `home-manager.sharedModules` where `config` is HM config, but they reference `config.hyprflake.*` which is NixOS config — must use `osConfig` instead. Verify `windowrulev2` is the correct key name for the current Hyprland HM module version.

**Files:** `modules/desktop/hyprland/default.nix`

---

## 5. Fix TLP settings type (Quick Win)

**Why:** `hyprflake.system.power.tlp.settings` uses `lib.types.attrs` which bypasses the module system's merge logic. Multiple definitions silently overwrite instead of merging.

**What:** Change `type = lib.types.attrs` to `type = lib.types.attrsOf lib.types.anything`.

**Files:** `modules/options.nix` line 517 (or power module after split)

---

## 6. Create missing architecture.md (Quick Win)

**Why:** `CLAUDE.md` references `extras/docs/architecture.md` but the file doesn't exist.

**What:** Create the file documenting: module tree overview, options flow, Stylix integration pattern, consumer import pattern, module structure convention, and the enable toggle pattern.

**Files:** `extras/docs/architecture.md` (new)

---

## Execution Order

1. **Fix existing lint violations** — run `statix check .` and `deadnix --fail .`, fix issues
2. **CI workflow** (item 1) — validates all subsequent changes
3. **Options split** (item 2) — pure refactor, zero behavioral change, own commit
4. **Enable toggles** (item 3) — behavioral change (adding options), separate commit after split
5. **Window rules fix** (item 4) — independent quick fix
6. **TLP type fix** (item 5) — one-line change, fold into options split or separate
7. **Architecture docs** (item 6) — write after structural changes land

## Verification

- `nix flake check` passes after each change
- `nix fmt -- --check` clean
- `statix check .` and `deadnix --fail .` clean
- Consumers can set `hyprflake.desktop.swaync.enable = false` (etc.) after item 3
- All existing behavior preserved (enable defaults are `true`)

## Deliberately Excluded

- **Stub system modules** (audio, fonts, graphics, xdg) — new features, not improvements
- **Plymouth TODOs** — enhancement wishes dependent on upstream packaging
- **Pre-commit hooks** — CI provides the same safety net with less setup friction
- **test.sh in CI** — requires a running Hyprland session, cannot run headless
