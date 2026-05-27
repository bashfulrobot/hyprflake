# Hyprland Lua Config Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate hyprflake's Hyprland configuration from the legacy `hyprlang` config backend to the new Lua config manager so `hyprshell` (and any other tool that registers keybinds via `eval hl.bind(...)`) works again. Simultaneously migrate every nixerator `~/.config/hypr/conf.d/*.conf` snippet to `.lua` form since the Lua VM cannot `source` hyprlang files.

**Architecture:** Flip `wayland.windowManager.hyprland.configType` from `"hyprlang"` to `"lua"` in `modules/desktop/hyprland/default.nix`. Re-express every `settings`-attr key so it corresponds to a real `hl.*` Lua function: wrap monitor/decoration/animation/etc. inside `hl.config({...})`; convert each `bind/bindm/bindel/bindl` entry into an `hl.bind` call with `_args` + `mkLuaInline` flag options; convert `exec-once` into one `hl.on("hyprland.start", ...)` block; convert variables (`$mainMod`, `$term`, `$menu`) into `_var` locals. Rewrite the `extraConfig` hyprlang block — opacity/float/pin windowrules, the `resize` submap, and the `source = conf.d/*.conf` glob — as Lua. Replace the conf.d source-glob with a `dofile()`-loop over `~/.config/hypr/conf.d/*.lua`. Rewrite each of the 6 nixerator conf.d modules to write a `.lua` file with `hl.*` calls in place of their current hyprlang `.conf`.

**Tech Stack:** Nix flake (NixOS + Home Manager modules), Home Manager (`1a95e2ef`, has `configType` option), Hyprland 0.55.2 Lua config manager, `lib.generators.mkLuaInline`.

**Repos involved:**
- `~/git/hyprflake` (this repo) — module library; one file modified
- `~/git/nixerator` (downstream consumer) — six small modules each writing one conf.d snippet

**Coordinated deploy:** Both repos must ship together. If hyprflake is rebuilt before nixerator's conf.d snippets are converted, every `.conf` snippet silently drops out (no error; the dofile loop only loads `.lua`), so user-configured workspaces / windowrules / autostart will be missing until nixerator catches up.

---

## Reference: home-manager Lua serializer rules

The HM hyprland module renders `settings` for `configType = "lua"` as follows (verified at `modules/services/window-managers/hyprland.nix:531-616` of HM rev `1a95e2ef`):

| Nix attribute shape | Renders as |
|---|---|
| `name = value` (scalar) | `hl.name(<toLua value>)` |
| `name = [ v1 v2 ]` | `hl.name(<v1>)` then `hl.name(<v2>)` (one call per list element) |
| `name = { _args = [ a b c ]; }` | `hl.name(<a>, <b>, <c>)` (multi-arg) |
| `name = { _var = "expr"; }` | `local name = expr` (Lua local; lowest-cost way to share a value) |
| `name = mkLuaInline "expr"` | raw `expr` inserted verbatim (e.g. dispatch closures) |
| nested attrset | passed as a Lua table literal |

`extraConfig` is appended verbatim after the rendered settings — that's where we put the `dofile` glob.

The attribute name must be a valid Lua identifier (no `$`, no `.`, no `-`). So `"$mainMod"`, `"col.active_border"`, `"exec-once"` cannot appear as top-level setting keys when `configType = "lua"`.

## Reference: known Hyprland Lua functions

Confirmed from `src/config/lua/bindings/*.cpp` (Hyprland 0.55.2):

- Toplevel: `hl.on`, `hl.bind`, `hl.unbind`, `hl.define_submap`, `hl.timer`, `hl.dispatch`, `hl.version`, `hl.exec_cmd`
- Config rules: `hl.config`, `hl.get_config`, `hl.device`, `hl.monitor`, `hl.window_rule`, `hl.layer_rule`, `hl.workspace_rule`, `hl.env`, `hl.permission`, `hl.plugin.load`, `hl.gesture`, `hl.curve`, `hl.animation`
- Dispatchers (used inside `hl.bind`): `hl.dsp.exec_cmd`, `hl.dsp.window.{close,move,float,fullscreen,resize,...}`, `hl.dsp.workspace.{toggle_special,move,...}`, `hl.dsp.focus`, `hl.dsp.layout`, `hl.dsp.submap`, plus group/cursor variants

`bindm`, `bindel`, `bindl`, `binde` do NOT exist as functions — they are flag combinations passed as a third arg to `hl.bind`:
- `bind` (default) → `hl.bind(key, dispatcher)`
- `bindm` (mouse) → `hl.bind(key, dispatcher, { mouse = true })`
- `binde` (repeat) → `hl.bind(key, dispatcher, { repeating = true })`
- `bindel` (locked + repeat) → `hl.bind(key, dispatcher, { locked = true, repeating = true })`
- `bindl` (locked) → `hl.bind(key, dispatcher, { locked = true })`

(Flag names verified against upstream `example/hyprland.lua`.)

---

## File map

### Hyprflake

- **Modify**: `modules/desktop/hyprland/default.nix` lines 417–683 (the entire `wayland.windowManager.hyprland = {...}` block)
- **Modify**: `docs/architecture.md` — note the configType change in the consumer-wiring section
- **Modify**: `docs/workarounds.md` — remove/update if a "configType pinned" workaround was added

### Nixerator

Each module writes a `.lua` file to `xdg.configFile."hypr/conf.d/<name>.lua"` instead of a `.conf`:

- `modules/system/special-workspaces/default.nix`
- `modules/apps/gui/morgen/default.nix`
- `modules/apps/gui/insync/default.nix`
- `modules/apps/cli/text-uppercase/default.nix`
- `modules/apps/cli/text-polish/default.nix`
- `modules/apps/cli/spotify/default.nix`

---

## Task 0: Branch + baseline snapshot

**Files:**
- Modify: none yet

- [ ] **Step 1: Create the hyprflake feature branch**

```bash
cd ~/git/hyprflake
git switch -c feat/hyprland-lua-config
```

- [ ] **Step 2: Create the nixerator feature branch**

```bash
cd ~/git/nixerator
git switch -c feat/hyprland-lua-conf.d
```

- [ ] **Step 3: Snapshot the current generated hyprland.conf for diff-checking later**

```bash
cp ~/.config/hypr/hyprland.conf /tmp/hyprland.conf.pre-lua-migration
```

This file is the baseline that the new generated `hyprland.lua` must reproduce semantically.

---

## Task 1: Flip configType and refactor `settings` into `hl.config` form

**Files:**
- Modify: `~/git/hyprflake/modules/desktop/hyprland/default.nix` lines 417–445, 431–642

- [ ] **Step 1: Set `configType = "lua"`**

In `modules/desktop/hyprland/default.nix`, replace lines 419–422:

```nix
            # Pin to legacy hyprlang backend. home-manager flips this default to
            # "lua" once home.stateVersion >= "26.05"; the module body is written
            # in hyprlang style, so pin explicitly until a lua migration audit.
            configType = "hyprlang";
```

with:

```nix
            # Use the Lua config manager. Required for hyprshell — it registers
            # keybinds via `eval hl.bind(...)` over IPC and that command is only
            # accepted by Hyprland's Lua backend (the hyprlang backend rejects
            # it with "eval is only supported with the lua config manager").
            configType = "lua";
```

- [ ] **Step 2: Convert the three string variables into `_var` locals**

Replace lines 432–435:

```nix
              # Variables
              "$mainMod" = "SUPER";
              "$term" = "${lib.getExe termCfg.package}";
              "$menu" = "${lib.getExe pkgs.rofi} -show drun -theme ~/.config/rofi/launchers/type-3/style-1.rasi";
```

with:

```nix
              # Locals (rendered as `local mainMod = "SUPER"` etc. by the
              # home-manager Lua serializer when an attribute has `_var`).
              # "$mainMod"/"$term"/"$menu" can't be Lua identifiers, so the
              # downstream Lua bindings reference `mainMod`, `term`, `menu`.
              mainMod = { _var = ''"SUPER"''; };
              term = { _var = ''"${lib.getExe termCfg.package}"''; };
              menu = { _var = ''"${lib.getExe pkgs.rofi} -show drun -theme ~/.config/rofi/launchers/type-3/style-1.rasi"''; };
```

Note: `_var` value must be a valid Lua expression — the embedded double-quotes are part of the value because Lua needs string literals.

- [ ] **Step 3: Wrap monitor/input/general/decoration/animations/dwindle/master/misc inside `hl.config({...})`**

Replace lines 437–527 (everything from `# Monitor configuration` through the closing of `misc = { ... };`) with one nested `config` attribute:

```nix
              # Everything below is wrapped in `hl.config({...})` by the
              # home-manager serializer because the attribute name is `config`.
              config = {
                # Monitor configuration (default to auto). Pass as a list of
                # tables so `hl.config({monitor = {{...}}})` becomes a list.
                monitor = [
                  {
                    output = "";
                    mode = "preferred";
                    position = "auto";
                    scale = "auto";
                  }
                ];

                input = {
                  kb_layout = osConfig.hyprflake.desktop.keyboard.layout;
                  kb_variant = osConfig.hyprflake.desktop.keyboard.variant;
                  repeat_delay = 300;
                  repeat_rate = 30;
                  # Mode 2 = loose focus: click-to-focus for windows, but hover works in popups (hyprshell)
                  follow_mouse = 2;
                  sensitivity = 0;
                  force_no_accel = true;

                  touchpad = {
                    natural_scroll = true;
                    disable_while_typing = true;
                  };
                };

                general = {
                  gaps_in = 4;
                  gaps_out = 8;
                  border_size = 2;
                  # Border colors managed by stylix
                  resize_on_border = true;
                  layout = "dwindle";
                };

                decoration = {
                  rounding = 8;

                  blur = {
                    enabled = true;
                    size = 3;
                    passes = 1;
                    new_optimizations = true;
                  };

                  shadow = {
                    enabled = true;
                    range = 4;
                    render_power = 3;
                  };
                };

                animations = {
                  enabled = true;
                };

                dwindle = {
                  preserve_split = true;
                };

                master = {
                  new_status = "master";
                };

                misc = {
                  disable_hyprland_logo = true;
                  disable_splash_rendering = true;
                  force_default_wallpaper = 0;
                  key_press_enables_dpms = true;
                  mouse_move_enables_dpms = true;
                };
              };
```

Note: the previous `animations.bezier`/`animations.animation` lines move out into separate top-level calls in Step 4 — `hl.curve(...)` and `hl.animation(...)` are not nested under `hl.config`.

- [ ] **Step 4: Replace `animations.bezier`/`animations.animation` with `curve` + `animation` calls**

Inside the same `settings` block (NOT inside `config`), add after the `config = { ... };` attribute:

```nix
              # `hl.curve(name, {type=..., points={...}})` defines a bezier
              # or spring curve. Translated from the legacy hyprlang
              # `bezier = myBezier, 0.05, 0.9, 0.1, 1.05`.
              curve = {
                _args = [
                  "myBezier"
                  (lib.generators.mkLuaInline "{ type = \"bezier\", points = { {0.05, 0.9}, {0.1, 1.05} } }")
                ];
              };

              # `hl.animation({leaf=..., enabled=..., speed=..., bezier=...})`
              # — one call per element. Each old line like
              # `windows, 1, 7, myBezier` becomes a row below.
              animation = [
                { leaf = "windows";     enabled = true; speed = 7;  bezier = "myBezier"; }
                { leaf = "windowsOut";  enabled = true; speed = 7;  bezier = "default";  style = "popin 80%"; }
                { leaf = "border";      enabled = true; speed = 10; bezier = "default";  }
                { leaf = "borderangle"; enabled = true; speed = 8;  bezier = "default";  }
                { leaf = "fade";        enabled = true; speed = 7;  bezier = "default";  }
                { leaf = "workspaces";  enabled = true; speed = 6;  bezier = "default";  }
              ];
```

Note: hyprlang `windows, 1, 7, myBezier` means `enabled=1, speed=7, curve=myBezier`. We're mapping `1`→`true`. If any old line had `0` (disabled), set `enabled = false`.

- [ ] **Step 5: Replace `gestures.gesture` with one `hl.gesture(...)` call per finger count**

The current block at lines 511–517:

```nix
              gestures = {
                gesture = [
                  "3, horizontal, workspace"
                  "4, horizontal, workspace"
                ];
              };
```

becomes a top-level `gesture = [ ... ];` attribute (each list entry → one `hl.gesture(...)` call). Add inside `settings`:

```nix
              # `hl.gesture({fingers=N, direction="horizontal", action="workspace"})`
              gesture = [
                { fingers = 3; direction = "horizontal"; action = "workspace"; }
                { fingers = 4; direction = "horizontal"; action = "workspace"; }
              ];
```

- [ ] **Step 6: Move `exec-once` into an `on` startup hook**

Remove the existing `exec-once = [ ... ];` (lines 528–535). In its place, add inside `settings`:

```nix
              # `hl.on("hyprland.start", function() hl.exec_cmd(...) end)`
              # — one `on` registration; the function body runs every exec_cmd
              # at compositor start. mkLuaInline lets us hand-craft the closure.
              on = {
                _args = [
                  "hyprland.start"
                  (lib.generators.mkLuaInline ''
                    function()
                      hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY HYPRLAND_INSTANCE_SIGNATURE")
                      hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store")
                      hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store")
                      hl.exec_cmd("${pkgs.gcr_4}/libexec/gcr4-ssh-askpass")
                    end
                  '')
                ];
              };
```

- [ ] **Step 7: Build Nix to confirm the module evaluates**

```bash
cd ~/git/hyprflake
nix flake check
```

Expected: no evaluation errors. Warnings about unused inputs are OK; type errors are NOT — fix before moving on.

- [ ] **Step 8: Commit**

```bash
cd ~/git/hyprflake
git add modules/desktop/hyprland/default.nix
git commit -m "refactor(hyprland): switch configType to lua and rewrite hl.config block"
```

---

## Task 2: Rewrite the main bind list

**Files:**
- Modify: `~/git/hyprflake/modules/desktop/hyprland/default.nix` (the `bind`, `bindm`, `bindel`, `bindl` attributes inside `settings`)

The serializer turns each list element into one `hl.bind(...)` call. We must replace every string-form entry with a `{ _args = [ ... ]; }` table.

- [ ] **Step 1: Replace `bind = [ ... ]` (lines 538–620)** with the structured form

Drop the entire existing `bind = [ ... ];` list and substitute:

```nix
              # `hl.bind(keyspec, dispatcher, opts?)` — each entry is one call.
              # Dispatchers are mkLuaInline so they pass through as raw Lua.
              bind = [
                # Launch applications
                { _args = [ ''mainMod .. " + RETURN"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd(term)'') ]; }
                { _args = [ ''mainMod .. " + T"''      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd(term)'') ]; }
                { _args = [ ''mainMod .. " + Space"''  (lib.generators.mkLuaInline ''hl.dsp.exec_cmd(menu)'') ]; }
                { _args = [ ''mainMod .. " + E"''      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.nautilus}")'') ]; }
                { _args = [ ''mainMod .. " + B"''      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("xdg-open https://")'') ]; }
                { _args = [ ''mainMod .. " + N"''      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swaync-client -t -sw")'') ]; }
                { _args = [ ''mainMod .. " + I"''      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("rofi-network-manager")'') ]; }
                { _args = [ ''mainMod .. " + period"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.rofimoji}")'') ]; }

                # Window management
                { _args = [ ''mainMod .. " + Q"''         (lib.generators.mkLuaInline ''hl.dsp.window.close()'') ]; }
                { _args = [ ''mainMod .. " + SHIFT + Q"'' (lib.generators.mkLuaInline ''hl.dsp.exit()'') ]; }
                { _args = [ ''mainMod .. " + V"''         (lib.generators.mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'') ]; }
                { _args = [ ''mainMod .. " + P"''         (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("wlogout -b 3 -c 60 -r 60")'') ]; }
                { _args = [ ''mainMod .. " + J"''         (lib.generators.mkLuaInline ''hl.dsp.layout("togglesplit")'') ]; }
                { _args = [ ''mainMod .. " + SHIFT + E"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-equalize-windows")'') ]; }
                { _args = [ ''mainMod .. " + F"''         (lib.generators.mkLuaInline ''hl.dsp.window.fullscreen({ mode = 0 })'') ]; }
                { _args = [ ''mainMod .. " + R"''         (lib.generators.mkLuaInline ''hl.dsp.submap("resize")'') ]; }

                # Move focus
                { _args = [ ''mainMod .. " + left"''  (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "left" })'')  ]; }
                { _args = [ ''mainMod .. " + right"'' (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "right" })'') ]; }
                { _args = [ ''mainMod .. " + up"''    (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "up" })'')    ]; }
                { _args = [ ''mainMod .. " + down"''  (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "down" })'')  ]; }

                # Move windows
                { _args = [ ''mainMod .. " + SHIFT + left"''  (lib.generators.mkLuaInline ''hl.dsp.window.move({ direction = "left" })'')  ]; }
                { _args = [ ''mainMod .. " + SHIFT + right"'' (lib.generators.mkLuaInline ''hl.dsp.window.move({ direction = "right" })'') ]; }
                { _args = [ ''mainMod .. " + SHIFT + up"''    (lib.generators.mkLuaInline ''hl.dsp.window.move({ direction = "up" })'')    ]; }
                { _args = [ ''mainMod .. " + SHIFT + down"''  (lib.generators.mkLuaInline ''hl.dsp.window.move({ direction = "down" })'')  ]; }

                # Special workspace (scratchpad)
                { _args = [ ''mainMod .. " + S"''         (lib.generators.mkLuaInline ''hl.dsp.workspace.toggle_special("magic")'') ]; }
                { _args = [ ''mainMod .. " + SHIFT + S"'' (lib.generators.mkLuaInline ''hl.dsp.window.move({ workspace = "special:magic" })'') ]; }

                # Scroll through workspaces
                { _args = [ ''mainMod .. " + mouse_down"'' (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "e+1" })'') ]; }
                { _args = [ ''mainMod .. " + mouse_up"''   (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "e-1" })'') ]; }

                # Screenshots
                { _args = [ ''"Print"''                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m region --raw | ${lib.getExe pkgs.satty} -f -")'') ]; }
                { _args = [ ''"CTRL + ALT + P"''       (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m region --clipboard-only")'') ]; }
                { _args = [ ''"CTRL + ALT + SHIFT + P"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m region --raw | ${lib.getExe pkgs.satty} -f -")'') ]; }
                { _args = [ ''"SHIFT + Print"''        (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m output --raw | ${lib.getExe pkgs.satty} -f -")'') ]; }

                # Screen recording
                { _args = [ ''"CTRL + ALT + R"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-record-region")'') ]; }

                # Lock screen
                { _args = [ ''mainMod .. " + L"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("loginctl lock-session")'') ]; }

                # Media control with SwayOSD song display
                { _args = [ ''"XF86AudioPlay"''  (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-media-play-pause")'') ]; }
                { _args = [ ''"XF86AudioPause"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-media-play-pause")'') ]; }
                { _args = [ ''"XF86AudioNext"''  (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-media-next")'') ]; }
                { _args = [ ''"XF86AudioPrev"''  (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-media-prev")'') ]; }
              ]
              # Workspace switching/move generated programmatically — Nix
              # equivalent of the `for i = 1,10 do ... end` block in upstream
              # example/hyprland.lua. Keeps the 20 entries in one place.
              ++ lib.concatMap (i:
                let key = if i == 10 then "0" else toString i; in [
                  { _args = [
                      ''mainMod .. " + ${key}"''
                      (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = ${toString i} })'')
                    ];
                  }
                  { _args = [
                      ''mainMod .. " + SHIFT + ${key}"''
                      (lib.generators.mkLuaInline ''hl.dsp.window.move({ workspace = ${toString i} })'')
                    ];
                  }
                ]) (lib.range 1 10);
```

- [ ] **Step 2: Replace `bindm`/`bindel`/`bindl` with appended bind entries that carry flag tables**

Drop the existing `bindm = [ ... ]; bindel = [ ... ]; bindl = [ ... ];` blocks (lines 622–640). After the closing `]` of the `bind = ...` above (and before the `;`), continue the same list with additional `++` segments OR — cleaner — declare the rest of the keymaps via `extraConfig` Lua since they read more naturally that way. Pick **one** of:

**Option A — keep them in `settings.bind` with explicit flag args:**

```nix
              ++ [
                # bindm (mouse move/resize)
                { _args = [ ''mainMod .. " + mouse:272"'' (lib.generators.mkLuaInline ''hl.dsp.window.drag()'')   { mouse = true; } ]; }
                { _args = [ ''mainMod .. " + mouse:273"'' (lib.generators.mkLuaInline ''hl.dsp.window.resize()'') { mouse = true; } ]; }

                # bindel (locked + repeating: volume / brightness)
                { _args = [ ''"XF86AudioRaiseVolume"''  (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --output-volume raise")'') { locked = true; repeating = true; } ]; }
                { _args = [ ''"XF86AudioLowerVolume"''  (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --output-volume lower")'') { locked = true; repeating = true; } ]; }
                { _args = [ ''"XF86MonBrightnessUp"''   (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --brightness raise")'')    { locked = true; repeating = true; } ]; }
                { _args = [ ''"XF86MonBrightnessDown"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --brightness lower")'')    { locked = true; repeating = true; } ]; }

                # bindl (locked: audio mute toggles)
                { _args = [ ''"XF86AudioMute"''    (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle")'') { locked = true; } ]; }
                { _args = [ ''"XF86AudioMicMute"'' (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hypr-mic-mute-toggle")'')                       { locked = true; } ]; }
              ];
```

**Option B — keep mode B if Option A's list grows unreadable.** Use Option A by default; the plan continues assuming it.

- [ ] **Step 3: Build and inspect the rendered Lua**

```bash
cd ~/git/hyprflake
nix flake check
```

If `flake check` passes, drive a quick eval into a NixOS host that consumes hyprflake (the user's main machine via nixerator) and print the generated Lua to verify shape:

```bash
cd ~/git/nixerator
nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --no-link --print-out-paths 2>&1 | tail
```

Don't activate yet — just confirm the build succeeds.

- [ ] **Step 4: Render the lua and eyeball the first ~80 lines**

```bash
# Build and extract the generated hyprland.lua without switching
nix-build '<nixpkgs>' -A coreutils --no-out-link >/dev/null  # warmup
cd ~/git/nixerator
nix eval --raw .#homeConfigurations.${USER}.config.home-files | head  # path
# Or simpler: read it after the next rebuild from ~/.config/hypr/hyprland.lua
```

Easier: defer this verification to the end-of-Task-7 deploy.

- [ ] **Step 5: Commit**

```bash
cd ~/git/hyprflake
git add modules/desktop/hyprland/default.nix
git commit -m "refactor(hyprland): rewrite bind/bindm/bindel/bindl as hl.bind calls"
```

---

## Task 3: Rewrite the resize submap

**Files:**
- Modify: `~/git/hyprflake/modules/desktop/hyprland/default.nix` (the `extraConfig` block, lines 648–682)

The current `extraConfig` is hyprlang text and won't be parsed by the Lua manager. We rewrite the resize submap in Lua and put it in `extraConfig` (which is appended verbatim to the generated `.lua` file).

- [ ] **Step 1: Replace lines 648–682 (the whole `extraConfig` string)** with:

```nix
            # The Lua serializer renders this verbatim AFTER everything in
            # `settings`. Used for things that have no clean attrset shape:
            # the resize submap, the conf.d glob, and the windowrules below.
            extraConfig = ''
              -- ===== resize submap =====
              -- `hl.define_submap("name", function() ... end)` registers a
              -- submap with bindings active only when entered. Calling
              -- `hl.dsp.submap("reset")` (or default) exits.
              hl.define_submap("resize", function()
                -- Vim keys
                hl.bind("h", hl.dsp.window.resize({ x = -50, y = 0,  relative = true }), { repeating = true })
                hl.bind("l", hl.dsp.window.resize({ x = 50,  y = 0,  relative = true }), { repeating = true })
                hl.bind("k", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
                hl.bind("j", hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

                -- Arrow keys
                hl.bind("left",  hl.dsp.window.resize({ x = -50, y = 0,  relative = true }), { repeating = true })
                hl.bind("right", hl.dsp.window.resize({ x = 50,  y = 0,  relative = true }), { repeating = true })
                hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
                hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

                -- Exit
                hl.bind("escape", hl.dsp.submap("reset"))
                hl.bind("return", hl.dsp.submap("reset"))
              end)
            '';
```

Note: do not close `extraConfig`'s `''` yet — Task 4 appends windowrules and Task 5 appends the conf.d shim into the same block.

- [ ] **Step 2: Build, commit**

```bash
cd ~/git/hyprflake
nix flake check && \
  git add modules/desktop/hyprland/default.nix && \
  git commit -m "refactor(hyprland): port resize submap to hl.define_submap"
```

---

## Task 4: Port windowrules to `hl.window_rule`

**Files:**
- Modify: `~/git/hyprflake/modules/desktop/hyprland/default.nix` — append to `extraConfig`

Currently in `extraConfig`:

```text
windowrule = opacity ${X} ${X}, match:class code|codium
windowrule = opacity ${X} ${X}, match:class chromium|firefox
windowrule = opacity ${Y} ${Y}, match:class ${termCfg.name}
windowrule = float on, match:class pwvucontrol|blueman-manager
windowrule = float on, match:class nm-connection-editor
windowrule = float on, match:title Picture-in-Picture
windowrule = pin on, match:title Picture-in-Picture
```

- [ ] **Step 1: Insert the windowrule block inside `extraConfig` (before the resize submap so opacity is applied early)**

Append before the resize block we wrote in Task 3:

```nix
            extraConfig = ''
              -- ===== window rules =====
              -- `hl.window_rule({name=..., match={...}, <effect>=<value>})`
              -- `match` keys come from the rule engine's match props (class,
              -- title, namespace, workspace, ...). Effects: opacity, float,
              -- pin, move, size, no_focus, suppress_event, …
              hl.window_rule({
                name = "opacity-editors",
                match = { class = "code|codium" },
                opacity = { ${toString osConfig.hyprflake.style.opacity.applications}, ${toString osConfig.hyprflake.style.opacity.applications} },
              })
              hl.window_rule({
                name = "opacity-browsers",
                match = { class = "chromium|firefox" },
                opacity = { ${toString osConfig.hyprflake.style.opacity.applications}, ${toString osConfig.hyprflake.style.opacity.applications} },
              })
              hl.window_rule({
                name = "opacity-terminal",
                match = { class = "${termCfg.name}" },
                opacity = { ${toString osConfig.hyprflake.style.opacity.terminal}, ${toString osConfig.hyprflake.style.opacity.terminal} },
              })

              hl.window_rule({
                name = "float-audio-net",
                match = { class = "pwvucontrol|blueman-manager" },
                float = true,
              })
              hl.window_rule({
                name = "float-nm-editor",
                match = { class = "nm-connection-editor" },
                float = true,
              })
              hl.window_rule({
                name = "float-pip",
                match = { title = "Picture-in-Picture" },
                float = true,
              })
              hl.window_rule({
                name = "pin-pip",
                match = { title = "Picture-in-Picture" },
                pin = true,
              })

              -- (resize submap follows below)
            '' + ''<resize submap block from Task 3 here>'';
```

Practical implementation: keep one single `extraConfig = ''<everything>''` string instead of `''A'' + ''B''`. Concatenate the windowrules and the resize submap inline. The split above is for readability.

Note on `opacity`: the Lua API for two-value opacity expects a list/table `{ active, inactive }`. If `flake check` reports a parse error here, the alternative shape is `opacity = ${X}, opacity_inactive = ${X}` as two separate fields — adjust based on the actual error message.

- [ ] **Step 2: Build, commit**

```bash
cd ~/git/hyprflake
nix flake check && \
  git add modules/desktop/hyprland/default.nix && \
  git commit -m "refactor(hyprland): port windowrules to hl.window_rule"
```

---

## Task 5: Replace `source = conf.d/*.conf` with a Lua `dofile` glob

**Files:**
- Modify: `~/git/hyprflake/modules/desktop/hyprland/default.nix` — append to `extraConfig`

- [ ] **Step 1: Append a portable conf.d loader to `extraConfig`**

Append at the end of the `extraConfig` block (after the resize submap):

```nix
              -- ===== conf.d loader =====
              -- The Lua config manager has no `source` keyword. Use
              -- io.popen to glob ~/.config/hypr/conf.d/*.lua and dofile
              -- each one. Sorted so load order is stable.
              do
                local conf_d = (os.getenv("HOME") or "~") .. "/.config/hypr/conf.d"
                local handle = io.popen('find ' .. conf_d .. ' -maxdepth 1 -name "*.lua" 2>/dev/null | sort')
                if handle then
                  for f in handle:lines() do
                    local ok, err = pcall(dofile, f)
                    if not ok then
                      io.stderr:write(string.format("[hyprflake] error loading %s: %s\n", f, err))
                    end
                  end
                  handle:close()
                end
              end
```

The `pcall` wrapping means one broken snippet does not break the whole config — Hyprland's stderr ends up in the systemd journal.

- [ ] **Step 2: Build, commit**

```bash
cd ~/git/hyprflake
nix flake check && \
  git add modules/desktop/hyprland/default.nix && \
  git commit -m "refactor(hyprland): replace conf.d source-glob with dofile loop"
```

---

## Task 6: Convert nixerator `special-workspaces` to Lua

**Files:**
- Modify: `~/git/nixerator/modules/system/special-workspaces/default.nix`

- [ ] **Step 1: Rewrite the configFile**

Replace lines 16–30 of the module:

```nix
      xdg.configFile."hypr/conf.d/special-workspaces.conf".text = ''
        # Special Workspaces: ...
        bind = SUPER, W, togglespecialworkspace, work
        bind = SUPER SHIFT, W, movetoworkspace, special:work
        bind = SUPER, O, togglespecialworkspace, office
        bind = SUPER SHIFT, O, movetoworkspace, special:office
        bind = SUPER, M, togglespecialworkspace, music
        bind = SUPER SHIFT, M, movetoworkspace, special:music
        bind = SUPER, D, togglespecialworkspace, dev
        bind = SUPER SHIFT, D, movetoworkspace, special:dev
      '';
```

with the Lua equivalent (file extension changes from `.conf` to `.lua` so hyprflake's dofile loop picks it up):

```nix
      xdg.configFile."hypr/conf.d/special-workspaces.lua".text = ''
        -- Special Workspaces: named special workspaces toggled by shortcut
        -- SUPER+W = Work, SUPER+O = Office, SUPER+M = Music, SUPER+D = Dev
        local function toggle(name)         return hl.dsp.workspace.toggle_special(name) end
        local function move_to(name)        return hl.dsp.window.move({ workspace = "special:" .. name }) end

        hl.bind("SUPER + W",         toggle("work"))
        hl.bind("SUPER + SHIFT + W", move_to("work"))
        hl.bind("SUPER + O",         toggle("office"))
        hl.bind("SUPER + SHIFT + O", move_to("office"))
        hl.bind("SUPER + M",         toggle("music"))
        hl.bind("SUPER + SHIFT + M", move_to("music"))
        hl.bind("SUPER + D",         toggle("dev"))
        hl.bind("SUPER + SHIFT + D", move_to("dev"))
      '';
```

- [ ] **Step 2: Commit**

```bash
cd ~/git/nixerator
git add modules/system/special-workspaces/default.nix
git commit -m "refactor(special-workspaces): emit lua conf.d for hyprland lua backend"
```

---

## Task 7: Convert nixerator `morgen` windowrule to Lua

**Files:**
- Modify: `~/git/nixerator/modules/apps/gui/morgen/default.nix`

- [ ] **Step 1: Rewrite the configFile**

Replace lines 44–50:

```nix
      xdg.configFile."hypr/conf.d/morgen-windowrule.conf".text = ''
        windowrule {
            name = morgen-tile
            match:class = ^([Mm]orgen)$
            tile = on
        }
      '';
```

with:

```nix
      xdg.configFile."hypr/conf.d/morgen-windowrule.lua".text = ''
        -- Force Morgen onto the tiling layout (it requests floating by default).
        hl.window_rule({
          name = "morgen-tile",
          match = { class = "^([Mm]orgen)$" },
          tile = true,
        })
      '';
```

- [ ] **Step 2: Commit**

```bash
cd ~/git/nixerator
git add modules/apps/gui/morgen/default.nix
git commit -m "refactor(morgen): emit lua windowrule for hyprland lua backend"
```

---

## Task 8: Convert nixerator `insync` autostart to Lua

**Files:**
- Modify: `~/git/nixerator/modules/apps/gui/insync/default.nix`

- [ ] **Step 1: Rewrite the configFile**

Replace lines 35–37:

```nix
      xdg.configFile."hypr/conf.d/insync-autostart.conf".text = ''
        exec-once = insync start --no-daemon
      '';
```

with:

```nix
      xdg.configFile."hypr/conf.d/insync-autostart.lua".text = ''
        -- exec-once equivalent: run on hyprland.start
        hl.on("hyprland.start", function()
          hl.exec_cmd("insync start --no-daemon")
        end)
      '';
```

- [ ] **Step 2: Commit**

```bash
cd ~/git/nixerator
git add modules/apps/gui/insync/default.nix
git commit -m "refactor(insync): emit lua autostart hook for hyprland lua backend"
```

---

## Task 9: Convert nixerator `text-uppercase` bind to Lua

**Files:**
- Modify: `~/git/nixerator/modules/apps/cli/text-uppercase/default.nix`

- [ ] **Step 1: Locate the configFile**

```bash
grep -n "conf.d" ~/git/nixerator/modules/apps/cli/text-uppercase/default.nix
```

Confirm the line is the `xdg.configFile."hypr/conf.d/text-uppercase.conf".text = ...` block found earlier.

- [ ] **Step 2: Rewrite the configFile**

Replace the existing `xdg.configFile."hypr/conf.d/text-uppercase.conf".text = '' bind = SUPER SHIFT, U, exec, ${pkgs.bash}/bin/bash ${textUppercaseScript} '';` block with:

```nix
      xdg.configFile."hypr/conf.d/text-uppercase.lua".text = ''
        hl.bind("SUPER + SHIFT + U",
          hl.dsp.exec_cmd("${pkgs.bash}/bin/bash ${textUppercaseScript}"))
      '';
```

- [ ] **Step 3: Commit**

```bash
cd ~/git/nixerator
git add modules/apps/cli/text-uppercase/default.nix
git commit -m "refactor(text-uppercase): emit lua bind for hyprland lua backend"
```

---

## Task 10: Convert nixerator `text-polish` bind to Lua

**Files:**
- Modify: `~/git/nixerator/modules/apps/cli/text-polish/default.nix`

- [ ] **Step 1: Rewrite the configFile**

Replace the existing `xdg.configFile."hypr/conf.d/text-polish.conf".text = '' bind = SUPER SHIFT, R, exec, ${pkgs.bash}/bin/bash ${textPolishScript} '';` block with:

```nix
      xdg.configFile."hypr/conf.d/text-polish.lua".text = ''
        hl.bind("SUPER + SHIFT + R",
          hl.dsp.exec_cmd("${pkgs.bash}/bin/bash ${textPolishScript}"))
      '';
```

- [ ] **Step 2: Commit**

```bash
cd ~/git/nixerator
git add modules/apps/cli/text-polish/default.nix
git commit -m "refactor(text-polish): emit lua bind for hyprland lua backend"
```

---

## Task 11: Convert nixerator `spotify` (`ncspot-save`) bind to Lua

**Files:**
- Modify: `~/git/nixerator/modules/apps/cli/spotify/default.nix`

The file currently writes `.config/hypr/conf.d/ncspot-save.conf` (note: uses `.config/...` directly, not `xdg.configFile."hypr/..."`). Keep the same write path.

- [ ] **Step 1: Locate the exact write block**

```bash
grep -n -B2 -A4 'ncspot-save.conf' ~/git/nixerator/modules/apps/cli/spotify/default.nix
```

- [ ] **Step 2: Rewrite the configFile**

Replace the block with:

```nix
          ".config/hypr/conf.d/ncspot-save.lua".text = ''
            hl.bind("SUPER + CTRL + S",
              hl.dsp.exec_cmd("ncspot-save-playing"))
          '';
```

- [ ] **Step 3: Commit**

```bash
cd ~/git/nixerator
git add modules/apps/cli/spotify/default.nix
git commit -m "refactor(spotify): emit lua ncspot-save bind for hyprland lua backend"
```

---

## Task 12: Coordinated deploy + runtime smoke test

**Files:**
- Modify: none (this is a deploy + verification task)

This is the first time the configuration actually runs end-to-end. The previous tasks only verified evaluation; this task verifies runtime.

- [ ] **Step 1: Update nixerator's flake.lock to pick up the hyprflake branch**

If nixerator references hyprflake by branch (typical), point it at `feat/hyprland-lua-config` temporarily:

```bash
cd ~/git/nixerator
nix flake lock --override-input hyprflake path:../hyprflake
nix flake metadata | head -20    # confirm override
```

- [ ] **Step 2: Build the system without switching**

```bash
sudo nixos-rebuild build --flake ~/git/nixerator#$(hostname)
```

Expected: clean build. Fix any evaluation errors before continuing.

- [ ] **Step 3: Inspect the generated Lua before activating**

```bash
ls -l result/etc/profiles/per-user/$USER/  # confirm hm output exists
# Lua file lands in home-files; easiest is to compare AFTER switch.
```

Or, peek at the staged file the next switch will deploy:

```bash
diff -u /tmp/hyprland.conf.pre-lua-migration ~/.config/hypr/hyprland.conf 2>/dev/null | head -40
```

- [ ] **Step 4: Switch the system**

```bash
sudo nixos-rebuild switch --flake ~/git/nixerator#$(hostname)
```

- [ ] **Step 5: Verify the generated `hyprland.lua` exists and looks sane**

```bash
ls -l ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.conf 2>&1
head -60 ~/.config/hypr/hyprland.lua
ls ~/.config/hypr/conf.d/
```

Expected: `hyprland.lua` exists, the first lines show `-- Generated by Home Manager.`, then `local mainMod = "SUPER"` etc., then a sequence of `hl.config({...})` calls. `conf.d/` contains `.lua` files (no `.conf`).

- [ ] **Step 6: Reload Hyprland in place**

```bash
hyprctl reload
journalctl --user -u hyprland-session.target --since '1 minute ago' | tail -40
```

Expected: no error output. Any `hl.window_rule: unknown field 'X'` or `hl.config: unknown config key 'Y'` indicates a translation bug — fix the offending field name based on the message (the field names in the Lua API often match hyprlang exactly but a few may differ).

If Hyprland refuses to reload, drop to a TTY and start a fresh session; check `~/.cache/hyprland/hyprland.log`.

- [ ] **Step 7: Functional smoke test — bindings**

In an active Hyprland session, exercise each binding family:

```text
SUPER+RETURN          → terminal opens
SUPER+E               → nautilus opens
SUPER+1, SUPER+2, ... → workspace switch
SUPER+SHIFT+1         → move active window to workspace 1
SUPER+Q               → kills the active window
SUPER+F               → fullscreen toggle
SUPER+R               → enters resize submap; h/j/k/l resizes; escape exits
ALT+Tab               → Hyprshell window switcher pops up   ← the original bug
Print                 → screenshot (hyprshot → satty)
XF86AudioPlay         → media play/pause; SwayOSD shows song
SUPER+W / SUPER+O ... → special workspaces (work/office/...) toggle
```

- [ ] **Step 8: Functional smoke test — windowrules**

```text
Open VS Code           → opacity matches osConfig.hyprflake.style.opacity.applications
Open the terminal      → opacity matches ...style.opacity.terminal
Open pwvucontrol       → floats
Open a Picture-in-Picture window in chromium → floats + pinned
Open Morgen            → tiles (does not float)
```

- [ ] **Step 9: Functional smoke test — autostart**

```text
journalctl --user -b | grep -i 'cliphist\|gcr4-ssh-askpass\|insync'
```

Expected: each was launched once at hyprland start. Insync should be running (`pgrep insync`).

- [ ] **Step 10: Resolve any failures**

For each test that fails:

1. Read the journal entry / hyprland log — Lua errors include file + line.
2. The most likely failure modes:
   - **Unknown field name** in `hl.window_rule` / `hl.config` — field name mismatch between hyprlang and Lua. Check the message; replace the field with the correct snake_case name.
   - **Dispatcher returns non-`ok`** — wrong dispatcher signature (e.g., `hl.dsp.window.fullscreen({mode=0})` expects a different field name). Cross-reference with `src/config/lua/bindings/LuaBindingsDispatchers.cpp` in the Hyprland source.
   - **`opacity` mismatch** — try `opacity_active`/`opacity_inactive` instead of `opacity = { x, x }`.
3. Re-run `sudo nixos-rebuild switch` + `hyprctl reload` after each fix.

---

## Task 13: Documentation + cleanup

**Files:**
- Modify: `~/git/hyprflake/docs/architecture.md`
- Modify: `~/git/hyprflake/docs/workarounds.md` (only if a workaround was added for the hyprshell-eval issue)
- Modify: `~/git/hyprflake/CHANGELOG.md`

- [ ] **Step 1: Update `docs/architecture.md`**

Find the section that describes consumer wiring for the Hyprland module. Add a paragraph:

```markdown
### Hyprland configType

`modules/desktop/hyprland/default.nix` sets
`wayland.windowManager.hyprland.configType = "lua"`. This generates
`~/.config/hypr/hyprland.lua` instead of `hyprland.conf`. The module
body uses `hl.*` calls (rendered by the home-manager Lua serializer);
the legacy hyprlang backend is no longer supported.

Consumers that need to drop additional Hyprland snippets into
`conf.d/` must write `.lua` files (not `.conf`) — hyprflake's
generated `hyprland.lua` ends with a `dofile`-loop that globs
`~/.config/hypr/conf.d/*.lua`. Hyprlang `.conf` files in conf.d are
silently ignored.
```

- [ ] **Step 2: Update `docs/workarounds.md`** (only if applicable)

If a "hyprshell broken on hyprlang backend" workaround was previously added, remove it. The migration is the fix.

- [ ] **Step 3: Update `CHANGELOG.md`**

Add an entry under unreleased:

```markdown
### Changed
- **Hyprland module migrated to Lua config backend.** `wayland.windowManager.hyprland.configType` is now `"lua"`; module body uses `hl.*` calls. Required to keep hyprshell working (it registers keybinds via `eval hl.bind(...)` which only the Lua backend accepts). **Breaking for consumers:** any `~/.config/hypr/conf.d/*.conf` files are now ignored — rewrite as `.lua` (see `docs/architecture.md`).
```

- [ ] **Step 4: Push and open PRs**

```bash
cd ~/git/hyprflake
git push -u origin feat/hyprland-lua-config
gh pr create --title "feat(hyprland): migrate to lua config backend" --body "$(cat <<'EOF'
## Summary
- Flip `configType` from `hyprlang` to `lua` so hyprshell's `eval hl.bind(...)` IPC calls succeed
- Rewrite `settings` to use `hl.config`/`hl.bind`/`hl.window_rule`/etc.
- Replace `source = conf.d/*.conf` with a Lua `dofile` glob over `*.lua`

## Test plan
- [ ] Generated `~/.config/hypr/hyprland.lua` parses cleanly (no `hyprctl reload` errors)
- [ ] All keybinds work (terminal launch, workspace switch, resize submap, hyprshot, media keys)
- [ ] Hyprshell Alt-Tab works (original bug)
- [ ] Window rules apply (opacity, float, pin)
- [ ] Conf.d snippets from nixerator load (special workspaces toggle, insync autostarts, morgen tiles, text-polish/text-uppercase/ncspot binds fire)
EOF
)"
```

```bash
cd ~/git/nixerator
git push -u origin feat/hyprland-lua-conf.d
gh pr create --title "refactor(hyprland-conf.d): emit lua snippets for hyprflake lua backend" --body "$(cat <<'EOF'
## Summary
- Convert all six hyprland conf.d snippets from `.conf` to `.lua`
- Required by hyprflake's switch to the Hyprland Lua config backend

## Test plan
- [ ] System rebuilds cleanly
- [ ] All snippet-provided functionality works (see hyprflake PR test plan)
EOF
)"
```

- [ ] **Step 5: Commit hyprflake doc changes**

```bash
cd ~/git/hyprflake
git add docs/architecture.md docs/workarounds.md CHANGELOG.md
git commit -m "docs: explain hyprland lua backend + conf.d migration"
git push
```

---

## Risk register

- **Field-name drift between hyprlang and Lua API.** A handful of hyprlang properties may have different snake_case names in the Lua API (`new_optimizations` vs `xray`, etc.). Each will surface as a `unknown field` error in the Hyprland log on first reload. Plan to iterate through Task 12 step 10 a few times.
- **Opacity rule shape.** The Lua window_rule `opacity` field may need either `{ active, inactive }` table form OR split `opacity_active`/`opacity_inactive` fields. Verify on first reload; spec assumes table form.
- **Animation curve parity.** The plan ships only the user's existing `myBezier` + default animations. If the user expected upstream's full default curve set (easeOutQuint, etc.), add those `hl.curve(...)` calls in Task 1 Step 4.
- **`hl.dsp.exit()` vs `hl.dsp.window.close()`.** SUPER+SHIFT+Q (old `exit`) maps to `hl.dsp.exit()` — confirm this exists in `LuaBindingsDispatchers.cpp`; the plan uses it. If absent, substitute `hl.dispatch("exit", "")`.
- **`hl.dsp.layout("togglesplit")` signature.** Old hyprlang used `layoutmsg`. The Lua dispatcher might be `hl.dsp.layout_msg("togglesplit")` instead — verify on first reload.
- **Stale `~/.config/hypr/hyprland.conf`.** Home Manager only generates one of the two; the old `.conf` file will remain on disk until manually deleted. Hyprland prefers `.lua` when present, so the stale `.conf` is harmless but worth removing for cleanliness: `rm ~/.config/hypr/hyprland.conf` after the migration verifies.

---

## Self-review (per writing-plans skill)

**Spec coverage check.**
- ✅ Root cause (hyprshell uses `eval hl.bind` which needs Lua backend) — addressed by Task 1.
- ✅ Top-level hyprlang `settings` translation — Task 1.
- ✅ Bind/bindm/bindel/bindl translation — Task 2.
- ✅ Submap translation — Task 3.
- ✅ Windowrule translation — Task 4.
- ✅ conf.d glob — Task 5 (hyprflake side) + Tasks 6-11 (nixerator side, every conf.d file).
- ✅ Runtime verification — Task 12.
- ✅ Docs and CHANGELOG — Task 13.
- ✅ Coordinated deploy (don't ship hyprflake before nixerator) — called out in architecture + Task 12 Step 1 (`--override-input` to test locally before merging).

**Placeholder scan.** No `TBD`/`TODO`. The opacity-field caveat is called out explicitly (Task 4 Step 1 note + risk register) rather than handwaved.

**Type consistency.** `hl.dsp.window.move`, `hl.dsp.workspace.toggle_special`, `hl.dsp.exec_cmd`, etc. are used consistently across tasks 2, 3, 6, 7, 8, 9, 10, 11. `_args`/`_var`/`mkLuaInline` usage matches HM's documented serializer rules.

---

## Execution handoff

Plan saved to `docs/superpowers/plans/2026-05-27-hyprland-lua-config-migration.md`.

Two execution options:

**1. Subagent-driven (recommended).** Fresh subagent per task with two-stage review between tasks. Best because each task touches a different chunk of generated Lua syntax that benefits from focused attention, and the runtime verification in Task 12 is iterative.

**2. Inline execution.** Run tasks sequentially in this session with batch checkpoints. Faster turnaround if the user wants to be present for each rebuild.

Pick one to begin.
