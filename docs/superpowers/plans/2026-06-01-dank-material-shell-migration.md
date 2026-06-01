# DankMaterialShell Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hyprflake's waybar-based desktop shell with DankMaterialShell (DMS) on the `feat/17-dank-shell` branch, testable from nixerator by repointing one flake input and reversible the same way.

**Architecture:** A new `modules/desktop/dank/` module imports DMS's upstream Home Manager module via `home-manager.sharedModules`, runs `pkgs.dms-shell` + `pkgs.quickshell` (prebuilt from nixpkgs), and is themed by the Stylix `dank-material-shell` target. The nine waybar-stack modules are gutted to options-only deprecation stubs so consumers (nixerator) keep evaluating unchanged. The hyprland module's keybinds are remapped to `dms ipc`, hyprpaper is retired (DMS owns the wallpaper), and shortcuts-viewer is rewritten to render `hyprctl binds -j` into a Stylix-themed HTML page opened in the browser.

**Tech Stack:** Nix (NixOS + Home Manager modules), DankMaterialShell (Quickshell/QML), Stylix (base16), Hyprland Lua config backend.

**Verification model:** This is declarative Nix config, not unit-testable code. Each task's "test" is `nixpkgs-fmt` + `statix` + `deadnix` + `nix flake check` in the hyprflake worktree, and (for integration tasks) a `nixos-rebuild build` of nixerator with `--override-input hyprflake path:<worktree>`. Files MUST end with a single trailing blank line (project rule).

**Reference facts (verified, do not re-derive):**
- nixpkgs provides `pkgs.dms-shell` (v1.4.6, `mainProgram = "dms"`) and `pkgs.quickshell`.
- DMS HM module namespace: `programs.dank-material-shell` (from the flake's `homeModules.dank-material-shell`). systemd unit `dms.service`, ExecStart `dms run --session`.
- DMS idle settings keys (top-level in `settings.json`, seconds, `0` = disabled): `acLockTimeout`, `batteryLockTimeout`, `acMonitorTimeout`, `batteryMonitorTimeout`, `acSuspendTimeout`, `batterySuspendTimeout`, `acSuspendBehavior`/`batterySuspendBehavior` (0=suspend), `lockBeforeSuspend` (bool), `loginctlLockIntegration` (default true).
- DMS IPC: `dms ipc spotlight toggle`, `dms ipc notifications toggle`, `dms ipc powermenu toggle`, `dms ipc lock lock`, `dms ipc clipboard toggle`, `dms ipc control-center toggle`, `dms ipc audio increment 3|decrement 3|mute|micmute`, `dms ipc brightness increment 5 ""|decrement 5 ""`, `dms ipc wallpaper set <path>`.
- Brightness: internal panel via logind (no `video` group / udev rule needed); external DDC needs `i2c-dev` kernel module + i2c access. Volume via DMS audio service.
- Stylix target: `stylix.targets.dank-material-shell.enable`; it writes colors (`currentThemeName="custom"` + theme file), fonts, opacity, and `session.wallpaperPath`. DMS's own `enableDynamicTheming` (matugen) should be off so it doesn't fight Stylix.

---

## File structure

**Created:**
- `modules/desktop/dank/default.nix` — DMS wiring (HM module import, package overrides, systemd, feature toggles, idle settings, owns `hyprflake.desktop.idle.*`).
- `modules/desktop/shortcuts-viewer/hypr-shortcuts-html.sh` — renders `hyprctl binds -j` into a themed HTML file and opens it.

**Modified:**
- `flake.nix` — add `dank-material-shell` input.
- `modules/default.nix` — add `./desktop/dank` to imports.
- `modules/desktop/stylix/default.nix` — enable the DMS Stylix target in `home-manager.sharedModules`.
- `modules/desktop/hyprland/default.nix` — remap binds to `dms ipc`, drop swayosd/rofi/swaync/wlogout/rofimoji refs, simplify media scripts, remove hyprpaper.
- `modules/desktop/shortcuts-viewer/default.nix` + `theme.nix` — HTML rewrite.
- Gutted to options-only stubs (delete all `config` that builds the shell, keep `options`, add a `warnings`): `waybar`, `waybar-auto-hide`, `swaync`, `swayosd`, `rofi`, `rofimoji`, `wlogout`, `hyprshell`, `hyprlock`, `hypridle`.
- Docs: `docs/architecture.md`, `docs/options.md`, `docs/styling.md`, `CLAUDE.md` topics, `docs/power-management.md` (idle).

---

## Task 1: Add the DMS flake input

**Files:**
- Modify: `flake.nix:4-31` (inputs block)

- [ ] **Step 1: Add the input**

In `flake.nix`, inside `inputs = { ... }`, after the `apple-fonts` block, add:

```nix
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Lock the input**

Run: `nix flake lock` in the worktree.
Expected: `flake.lock` gains a `dank-material-shell` node; no other nodes change meaningfully.

- [ ] **Step 3: Confirm the HM module output name**

Run: `nix eval --no-write-lock-file '.#' --apply 'x: null' 2>/dev/null; nix flake show github:AvengeMedia/DankMaterialShell/stable 2>&1 | grep -iE "homeModules|nixosModules"`
Expected: shows `homeModules.dank-material-shell` (and `.default`). If the attribute differs, record the real name; Task 4 uses it.

- [ ] **Step 4: Format + commit**

```bash
nixpkgs-fmt flake.nix
git add flake.nix flake.lock
git commit -m "feat(dank): add DankMaterialShell flake input"
```

---

## Task 2: Gut the waybar-stack modules to options-only stubs

Each module keeps its `options` block verbatim (so consumer assignments still type-check) but drops every `config` attribute that builds the shell, replacing it with a single `warnings` entry. This preserves nixerator's one-line rollback.

**Files (modify each):**
- `modules/desktop/waybar/default.nix`
- `modules/desktop/waybar-auto-hide/default.nix`
- `modules/desktop/swaync/default.nix`
- `modules/desktop/swayosd/default.nix`
- `modules/desktop/rofi/default.nix`
- `modules/desktop/rofimoji/default.nix`
- `modules/desktop/wlogout/default.nix`
- `modules/desktop/hyprshell/default.nix`
- `modules/desktop/hyprlock/default.nix`

- [ ] **Step 1: Gut `swaync` (template for the simple enable-only modules)**

Replace the whole `config = ...` block in `modules/desktop/swaync/default.nix` with:

```nix
  config = lib.mkIf config.hyprflake.desktop.swaync.enable {
    warnings = [
      "hyprflake.desktop.swaync is a no-op: notifications are now provided by DankMaterialShell (modules/desktop/dank). Remove this option from your config."
    ];
  };
```

Delete the now-unused `let stylix = ...; in` binding and any `style.nix` references at the top of the file. Keep the `options.hyprflake.desktop.swaync.enable` declaration.

Apply the identical pattern (swap the option path + message) to: `swayosd`, `rofimoji`, `wlogout`, `hyprshell`, `hyprlock`. For `rofi`, keep its multi-line `options.hyprflake.desktop.rofi.enable` declaration and gut `config` the same way.

- [ ] **Step 2: Gut `waybar` (keeps the rich option tree)**

In `modules/desktop/waybar/default.nix`, keep the entire `options.hyprflake.desktop.waybar = { ... }` block (enable, workspaceAppIcons.*, etc. — nixerator's `lib/mkWebApp.nix` sets `workspaceAppIcons.rewrites`). Delete the `let ... in` helper bindings and replace `config` with:

```nix
  config = lib.mkIf config.hyprflake.desktop.waybar.enable {
    warnings = [
      "hyprflake.desktop.waybar is a no-op: the status bar is now provided by DankMaterialShell (modules/desktop/dank). workspaceAppIcons.* options are ignored."
    ];
  };
```

- [ ] **Step 3: Gut `waybar-auto-hide`**

It also declares `options.hyprflake.desktop.waybar` (the `autoHide` sub-option). Keep that options block, drop config to a `warnings`-only `mkIf config.hyprflake.desktop.waybar.autoHide` (guard on whatever the real sub-option is; if it's `waybar.autoHide.enable`, guard on that). Message: `"hyprflake.desktop.waybar.autoHide is a no-op under DankMaterialShell."`

- [ ] **Step 4: Format, lint, flake check**

```bash
nixpkgs-fmt modules/desktop/{waybar,waybar-auto-hide,swaync,swayosd,rofi,rofimoji,wlogout,hyprshell,hyprlock}/default.nix
statix check modules/desktop/
deadnix modules/desktop/
nix flake check
```
Expected: flake check passes. deadnix may flag now-unused `pkgs`/`lib` args in gutted modules — remove the genuinely-unused ones it reports.

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/
git commit -m "refactor(dank): gut waybar-stack modules to deprecation stubs"
```

---

## Task 3: Move idle options into the dank module's ownership; gut hypridle

The `hyprflake.desktop.idle.*` options (currently declared in `hypridle/default.nix`) must stay live and feed DMS idle. Move them to the dank module (Task 4 declares them). Here we only gut hypridle's config and its `enable` stub.

**Files:**
- Modify: `modules/desktop/hypridle/default.nix`

- [ ] **Step 1: Remove the `options.hyprflake.desktop.idle` block** from `hypridle/default.nix` (Task 4 re-declares it). Keep `options.hyprflake.desktop.hypridle.enable`.

- [ ] **Step 2: Replace `config`** with:

```nix
  config = lib.mkIf config.hyprflake.desktop.hypridle.enable {
    warnings = [
      "hyprflake.desktop.hypridle is a no-op: idle/lock/DPMS are now handled by DankMaterialShell (modules/desktop/dank), configured via hyprflake.desktop.idle.*."
    ];
  };
```

- [ ] **Step 3: Commit (defer flake check to Task 4** — `hyprflake.desktop.idle` is temporarily undeclared between Step 1 and Task 4; do Task 4 before any eval).

```bash
git add modules/desktop/hypridle/default.nix
git commit -m "refactor(dank): gut hypridle; idle options move to dank module"
```

---

## Task 4: Create the dank module

**Files:**
- Create: `modules/desktop/dank/default.nix`
- Modify: `modules/default.nix` (add import)

- [ ] **Step 1: Write `modules/desktop/dank/default.nix`**

```nix
{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.hyprflake.desktop.dank;
  idle = config.hyprflake.desktop.idle;
in
{
  # DankMaterialShell desktop shell. Replaces the waybar stack (bar,
  # launcher, notifications, OSD, power menu) plus the lock screen and
  # idle daemon. Themed by the Stylix dank-material-shell target.

  options.hyprflake.desktop.dank.enable =
    lib.mkEnableOption "DankMaterialShell desktop shell" // { default = true; };

  # Idle ladder, consumed below to configure DMS idle. Lives here because
  # the dank module now owns idle (hypridle was retired). Same option
  # surface consumers used before so nothing downstream breaks.
  options.hyprflake.desktop.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Seconds before locking the session. 0 disables.";
    };
    dpmsTimeout = lib.mkOption {
      type = lib.types.int;
      default = 360;
      description = ''
        Seconds before turning displays off (DPMS). 0 disables.
        DMS drives this through the compositor's monitor power-off.
        Defaults to 360 (6 minutes); set 0 to keep the screen on.
      '';
    };
    suspendTimeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = "Seconds before suspend. 0 disables.";
    };
  };

  config = lib.mkIf cfg.enable {
    # External-monitor brightness (DDC) needs the i2c-dev device. Internal
    # panel brightness goes through logind and needs nothing extra.
    hardware.i2c.enable = true;

    home-manager.sharedModules = [
      hyprflakeInputs.dank-material-shell.homeModules.dank-material-shell
      ({ ... }: {
        programs.dank-material-shell = {
          enable = true;
          # Prebuilt from nixpkgs — avoids the flake's from-source build.
          package = pkgs.dms-shell;
          quickshell.package = pkgs.quickshell;

          # Autostart via the systemd user service (dms.service ->
          # `dms run --session`). Do NOT also exec-once from Hyprland.
          systemd.enable = true;

          # Stylix owns colors; turn off DMS's wallpaper-driven matugen so
          # the two color engines do not fight.
          enableDynamicTheming = false;

          # Idle ladder. Mirror AC and battery to the hyprflake.desktop.idle
          # values. Seconds; 0 disables a given listener.
          settings = {
            acLockTimeout = idle.lockTimeout;
            batteryLockTimeout = idle.lockTimeout;
            acMonitorTimeout = idle.dpmsTimeout;
            batteryMonitorTimeout = idle.dpmsTimeout;
            acSuspendTimeout = idle.suspendTimeout;
            batterySuspendTimeout = idle.suspendTimeout;
            lockBeforeSuspend = true;
            loginctlLockIntegration = true;
          };
        };
      })
    ];
  };
}
```

- [ ] **Step 2: Register the module**

In `modules/default.nix`, add `./desktop/dank` to the `imports` list (alphabetical, before `./desktop/display-manager`).

- [ ] **Step 3: Format, lint, flake check**

```bash
nixpkgs-fmt modules/desktop/dank/default.nix modules/default.nix
statix check modules/desktop/dank/
deadnix modules/desktop/dank/
nix flake check
```
Expected: PASS. If `homeModules.dank-material-shell` is the wrong attr (per Task 1 Step 3), fix the import path here.

- [ ] **Step 4: Commit**

```bash
git add modules/desktop/dank/default.nix modules/default.nix
git commit -m "feat(dank): DMS module with idle ladder and systemd autostart"
```

---

## Task 5: Enable the Stylix DMS target

**Files:**
- Modify: `modules/desktop/stylix/default.nix:380-382` (the existing `home-manager.sharedModules` list)

- [ ] **Step 1: Add the target**

Change the existing block:

```nix
    home-manager.sharedModules = [
      { stylix.targets.rofi.enable = false; }
    ];
```

to:

```nix
    home-manager.sharedModules = [
      {
        # rofi is retired; its Stylix target would error on a missing program.
        stylix.targets.rofi.enable = false;
        # DankMaterialShell theming: feed base16, fonts, opacity, wallpaper.
        stylix.targets.dank-material-shell.enable =
          config.hyprflake.desktop.dank.enable;
      }
    ];
```

- [ ] **Step 2: Flake check**

Run: `nix flake check`
Expected: PASS. If the target attr name differs, `nix flake check` errors with the offending path; correct it from the Stylix options page (`stylix.targets.dank-material-shell`).

- [ ] **Step 3: Commit**

```bash
nixpkgs-fmt modules/desktop/stylix/default.nix
git add modules/desktop/stylix/default.nix
git commit -m "feat(dank): enable Stylix dank-material-shell target"
```

---

## Task 6: Rewrite the Hyprland keybinds and remove hyprpaper

**Files:**
- Modify: `modules/desktop/hyprland/default.nix`

- [ ] **Step 1: Remove the rofi `menu` binding source**

Delete the `menu = "...rofi...";` line (`:424`). Remove `rofi-network-manager`, `qrencode`, `impala` from `environment.systemPackages` only if they are unused elsewhere (network is now `dms ipc control-center toggle`; keep `networkmanagerapplet`).

- [ ] **Step 2: Simplify the media scripts (drop swayosd)**

The `hypr-media-play-pause/next/prev` and `hypr-mic-mute-toggle` `writeShellApplication`s call `swayosd-client`. Replace their bodies so they no longer reference swayosd; DMS shows its own media/audio OSD. Example for play-pause:

```nix
  hypr-media-play-pause = pkgs.writeShellApplication {
    name = "hypr-media-play-pause";
    runtimeInputs = [ pkgs.playerctl ];
    text = "playerctl play-pause";
  };
```

Apply the same shape to `hypr-media-next` (`playerctl next`), `hypr-media-prev` (`playerctl previous`), and `hypr-mic-mute-toggle` (`dms ipc audio micmute`). Remove `pkgs.swayosd` from every `runtimeInputs`.

- [ ] **Step 3: Remap the application/shell binds**

In the `bind = [ ... ]` list, replace these entries:

```nix
  (mkBind "${mod} + Space" (luaInline ''hl.dsp.exec_cmd("dms ipc spotlight toggle")'') "App launcher")
  (mkBind "${mod} + N" (luaInline ''hl.dsp.exec_cmd("dms ipc notifications toggle")'') "Toggle notifications")
  (mkBind "${mod} + I" (luaInline ''hl.dsp.exec_cmd("dms ipc control-center toggle")'') "Control center (network)")
  (mkBind "${mod} + P" (luaInline ''hl.dsp.exec_cmd("dms ipc powermenu toggle")'') "Power menu")
  (mkBind "${mod} + C" (luaInline ''hl.dsp.exec_cmd("dms ipc clipboard toggle")'') "Clipboard history")
```

Delete the rofimoji bind (`${mod} + period`, `:616`). Leave `${mod} + period` unbound (freed).

- [ ] **Step 4: Remap volume/brightness/lock**

Replace the swayosd volume/brightness binds (`:672-679`) and the lock bind (`:658`):

```nix
  (mkBind "${mod} + L" (luaInline ''hl.dsp.exec_cmd("dms ipc lock lock")'') "Lock screen")
  (mkBindOpts "XF86AudioRaiseVolume" (luaInline ''hl.dsp.exec_cmd("dms ipc audio increment 3")'') { locked = true; repeating = true; } "Volume up")
  (mkBindOpts "XF86AudioLowerVolume" (luaInline ''hl.dsp.exec_cmd("dms ipc audio decrement 3")'') { locked = true; repeating = true; } "Volume down")
  (mkBindOpts "XF86MonBrightnessUp" (luaInline ''hl.dsp.exec_cmd("dms ipc brightness increment 5 \"\"")'') { locked = true; repeating = true; } "Brightness up")
  (mkBindOpts "XF86MonBrightnessDown" (luaInline ''hl.dsp.exec_cmd("dms ipc brightness decrement 5 \"\"")'') { locked = true; repeating = true; } "Brightness down")
  (mkBindOpts "XF86AudioMute" (luaInline ''hl.dsp.exec_cmd("dms ipc audio mute")'') { locked = true; } "Toggle audio mute")
  (mkBindOpts "XF86AudioMicMute" (luaInline ''hl.dsp.exec_cmd("dms ipc audio micmute")'') { locked = true; } "Toggle mic mute")
```

Keep `loginctl lock-session` working: DMS honors `loginctlLockIntegration`, so `loginctl lock-session` also triggers the DMS lock. The explicit `dms ipc lock lock` bind is the direct path.

- [ ] **Step 5: Remove hyprpaper (DMS owns the wallpaper)**

Delete the `xdg.configFile."hypr/hyprpaper.conf"` block (`:400-408`) and the `services.hyprpaper` block (`:412-415`). Remove `hyprpaper` from `environment.systemPackages` (`:224`). Stylix's DMS target sets `session.wallpaperPath`; DMS renders the wallpaper.

- [ ] **Step 6: Format, lint, flake check**

```bash
nixpkgs-fmt modules/desktop/hyprland/default.nix
statix check modules/desktop/hyprland/
deadnix modules/desktop/hyprland/
nix flake check
```
Expected: PASS. deadnix will flag any now-unused script bindings — if a media script was fully removed, delete its `let` binding and its `systemPackages` entry together.

- [ ] **Step 7: Commit**

```bash
git add modules/desktop/hyprland/default.nix
git commit -m "feat(dank): remap Hyprland binds to dms ipc; retire hyprpaper"
```

---

## Task 7: Rewrite shortcuts-viewer as a themed HTML page

**Files:**
- Create: `modules/desktop/shortcuts-viewer/hypr-shortcuts-html.sh`
- Modify: `modules/desktop/shortcuts-viewer/default.nix`
- Delete: `modules/desktop/shortcuts-viewer/hypr-shortcuts.sh`, `theme.nix`, `README.md` (replaced)

- [ ] **Step 1: Write the renderer script** `hypr-shortcuts-html.sh`

```bash
#!/usr/bin/env bash
# Render the live Hyprland keybind table to a themed HTML page and open it
# in the default browser. Bind data comes from `hyprctl binds -j` so it is
# always current and includes conf.d binds. Colors/fonts are injected at
# Nix build time (see default.nix) via the @@VAR@@ placeholders.
set -euo pipefail

out="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-shortcuts.html"
mkdir -p "$(dirname "$out")"

rows="$(hyprctl binds -j | jq -r '
  .[] | select(.description != "" and .description != null)
  | "<tr><td class=\"k\">" + (.modmask|tostring) + " " + .key + "</td><td>" + .description + "</td></tr>"
')"

cat > "$out" <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>Keybindings</title>
<style>
  body { background: @@BG@@; color: @@FG@@; font-family: "@@FONT@@"; padding: 2rem; }
  h1 { color: @@ACCENT@@; }
  table { border-collapse: collapse; width: 100%; }
  td { padding: .35rem .75rem; border-bottom: 1px solid @@ALT@@; }
  td.k { color: @@ACCENT@@; white-space: nowrap; font-weight: 600; }
</style></head><body>
<h1>Hyprland keybindings</h1>
<table>$rows</table>
</body></html>
HTML

xdg-open "$out"
```

Note: `modmask` is a numeric bitmask; rendering it raw is acceptable for v1. A follow-up can map it to `SUPER`/`SHIFT` text. Descriptions come from the `description` field that `mkBind`/`mkBindOpts` already populate, so hyprflake binds show readable labels; consumer `conf.d` binds that include `{ description = "..." }` show too.

- [ ] **Step 2: Rewrite `default.nix`**

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.shortcutsViewer;
  c = config.lib.stylix.colors;

  themed = builtins.replaceStrings
    [ "@@BG@@" "@@FG@@" "@@ALT@@" "@@ACCENT@@" "@@FONT@@" ]
    [
      "#${c.base00}"
      "#${c.base05}"
      "#${c.base01}"
      "#${c.base0D}"
      config.stylix.fonts.sansSerif.name
    ]
    (builtins.readFile ./hypr-shortcuts-html.sh);

  shortcutsScript = pkgs.writeShellApplication {
    name = "hypr-shortcuts";
    runtimeInputs = [ pkgs.hyprland pkgs.jq pkgs.coreutils pkgs.xdg-utils ];
    text = themed;
  };
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "hyprflake" "shortcuts-viewer" "defaultDisplay" ]
      [ "hyprflake" "desktop" "shortcutsViewer" "defaultDisplay" ])
    (lib.mkRenamedOptionModule
      [ "hyprflake" "shortcuts-viewer" "keybindings" "showBinds" ]
      [ "hyprflake" "desktop" "shortcutsViewer" "keybindings" "showBinds" ])
    (lib.mkRenamedOptionModule
      [ "hyprflake" "shortcuts-viewer" "keybindings" "showGlobal" ]
      [ "hyprflake" "desktop" "shortcutsViewer" "keybindings" "showGlobal" ])
  ];

  options.hyprflake.desktop.shortcutsViewer = {
    defaultDisplay = lib.mkOption {
      type = lib.types.enum [ "rofi" "terminal" "browser" ];
      default = "browser";
      description = "Display method. Only \"browser\" is implemented; rofi/terminal are deprecated no-ops kept for compatibility.";
    };
    keybindings = {
      showBinds = lib.mkOption {
        type = lib.types.lines;
        default = ''hl.bind("SUPER + slash", hl.dsp.exec_cmd("hypr-shortcuts"), { description = "Show keybindings" })'';
        description = "Lua hl.bind snippet for the cheat-sheet keybind (appended to extraConfig).";
      };
      showGlobal = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Optional extra Lua hl.bind snippet. Empty by default (the single HTML page covers everything).";
      };
    };
  };

  config = {
    home-manager.sharedModules = [
      (_: {
        home.packages = [ shortcutsScript ];
        wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''

          -- shortcuts-viewer keybind
          ${cfg.keybindings.showBinds}
          ${cfg.keybindings.showGlobal}
        '';
      })
    ];
  };
}
```

- [ ] **Step 3: Delete the replaced files**

```bash
git rm modules/desktop/shortcuts-viewer/hypr-shortcuts.sh modules/desktop/shortcuts-viewer/theme.nix modules/desktop/shortcuts-viewer/README.md
```

- [ ] **Step 4: Format, lint, flake check**

```bash
nixpkgs-fmt modules/desktop/shortcuts-viewer/default.nix
statix check modules/desktop/shortcuts-viewer/
deadnix modules/desktop/shortcuts-viewer/
nix flake check
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/desktop/shortcuts-viewer/
git commit -m "feat(dank): shortcuts-viewer renders live binds to themed HTML"
```

---

## Task 8: Full hyprflake flake check

- [ ] **Step 1: Clean build of the whole flake**

Run: `nix flake check 2>&1 | tail -30`
Expected: no errors. Resolve any remaining unused-arg warnings from `deadnix modules/`.

- [ ] **Step 2: Confirm no dangling references**

Run: `grep -rn "swayosd-client\|rofi-network-manager\|swaync-client\|wlogout\|rofimoji\|hyprpaper" modules/ | grep -v "stub\|no-op\|warnings"`
Expected: no functional references remain (matches only in comments/warnings are fine).

- [ ] **Step 3: Commit any cleanup**

```bash
git add -A && git commit -m "chore(dank): cleanup dangling shell references" || true
```

---

## Task 9: Consumer-eval validation against nixerator (the rollback proof)

**Files:** none (validation only). Runs in `~/git/nixerator`.

- [ ] **Step 1: Evaluate nixerator against the branch with zero edits**

Run (pick the host that imports hyprflake, e.g. `qbert`):
```bash
cd ~/git/nixerator
nixos-rebuild build --flake .#qbert \
  --override-input hyprflake path:/home/dustin/git/.worktrees/feat-17-dank-shell 2>&1 | tail -40
```
Expected: build succeeds. The deprecation `warnings` for waybar/swaync/etc. print but do not fail. This proves the stub principle: nixerator needs no edits.

- [ ] **Step 2: If eval errors on a missing option**, identify which option nixerator set that the stubs dropped, add it back to the relevant stub module's `options` block, re-run. Repeat until clean. (This is the whole point of Task 2/3 — any miss surfaces here.)

- [ ] **Step 3: Record the result** in the design doc's validation section (done / which options needed re-stubbing).

---

## Task 10: Runtime validation (manual, on real hardware)

**Files:** none. Requires switching nixerator to the branch and rebooting into the session.

- [ ] **Step 1: Switch nixerator to the branch input**

In `~/git/nixerator/flake.nix`, set `hyprflake.url = "github:bashfulrobot/hyprflake/feat/17-dank-shell";` (after pushing the branch in Task 11), `nix flake update hyprflake`, then `nixos-rebuild switch --flake .#<host>`. (Or use the local `--override-input` form to avoid pushing first.)

- [ ] **Step 2: Verify each shell surface**

Confirm in the live session: DMS bar visible; `SUPER+Space` launcher; `SUPER+N` notifications; `SUPER+P` power menu; `SUPER+L` lock; volume/brightness keys move the DMS OSD; `SUPER+I` opens control center with network; `SUPER+/` opens the themed HTML cheat-sheet in the browser and it lists nixerator's `conf.d` binds (SUPER+W/O/M/D, SUPER+CTRL+S).

- [ ] **Step 3: Verify the idle ladder (the hard requirement)**

Idle the machine. Confirm: locks at ~5 min, **displays turn off at ~6 min and wake cleanly on input**, suspends at ~10 min, and the session is locked on resume. If screen-off does not blank or does not wake (the failure mode that plagued hypridle), do NOT disable it — diagnose: check `dms ipc` monitor behavior, Hyprland `misc.key_press_enables_dpms`/`mouse_move_enables_dpms` (still set), and the GPU/cable path. Capture findings.

- [ ] **Step 4: Verify Stylix theming + external-monitor brightness**

DMS colors/fonts match the base16 scheme; wallpaper is the Stylix image; no matugen drift. If using an external monitor, confirm `i2c-dev` brightness works (Task 4 set `hardware.i2c.enable`); add the user to the `i2c` group if needed.

- [ ] **Step 5: Rollback drill**

Revert `hyprflake.url` to `github:bashfulrobot/hyprflake`, `nix flake update hyprflake`, rebuild. Confirm the waybar shell returns. This validates the one-line rollback.

---

## Task 11: Push the branch and update docs

**Files:**
- Modify: `docs/architecture.md`, `docs/options.md`, `docs/styling.md`, `docs/power-management.md`, `CLAUDE.md`

- [ ] **Step 1: Update docs**

- `architecture.md`: replace the waybar/swaync/swayosd/rofi/etc. module-tree entries with `dank/`; note the nine stubs; update the Stylix integration section to mention the DMS target; update the wallpaper note (DMS, not hyprpaper).
- `options.md`: document `hyprflake.desktop.dank.enable`, the relocated `hyprflake.desktop.idle.*` (new dpmsTimeout default 360), and mark the stubbed options deprecated.
- `styling.md`: document the `stylix.targets.dank-material-shell` wiring and `enableDynamicTheming = false`.
- `power-management.md`: document the DMS idle ladder mapping.
- `CLAUDE.md`: adjust the Docs index lines if any topic file scope changed.

- [ ] **Step 2: Format + commit docs**

```bash
nixpkgs-fmt . 2>/dev/null || true
git add docs/ CLAUDE.md
git commit -m "docs(dank): document DMS shell, idle ladder, stub deprecations"
```

- [ ] **Step 3: Push the branch**

```bash
git push -u origin feat/17-dank-shell
```
Expected: branch on origin so nixerator can consume `github:bashfulrobot/hyprflake/feat/17-dank-shell`.

---

## Self-review notes (spec coverage)

- Hard cutover, full replacement, DMS locker+idle, aggressive edge replacement: Tasks 2-7.
- rofimoji dropped: Task 6 Step 3. shortcuts-viewer rewritten (Option B): Task 7.
- DMS package prebuilt: Task 4 Step 1 (`pkgs.dms-shell` confirmed to exist).
- Wallpaper owned by DMS: Task 6 Step 5 + Stylix target Task 5.
- systemd autostart: Task 4. Idle ladder lock/screen-off/suspend + lock-before-suspend: Task 4 (`acMonitorTimeout` etc.). Reliable screen-off as hard gate: Task 10 Step 3.
- Consumer-eval compatibility (stubs) + one-line rollback: Task 2/3 + Task 9 + Task 10 Step 5.
- Stylix single source of truth, no matugen drift: Task 4 (`enableDynamicTheming = false`) + Task 5.
- Open risk carried into runtime gate: DPMS reliability on real hardware (Task 10 Step 3); external-monitor i2c brightness (Task 10 Step 4).
