# hl.bind entries. Every bind carries a description (shown by shortcuts-viewer).
{ lib, pkgs, termCfg }:

let
  # Strings used in keyspecs / dispatcher commands. Preconcatenated
  # in Nix so the Lua serializer sees plain string literals — the
  # Lua VM does no further substitution.
  mod = "SUPER";
  term = lib.getExe termCfg.package;

  # mkLuaInline alias to keep the bind list compact.
  luaInline = lib.generators.mkLuaInline;

  # Helpers for building hl.bind entries with mandatory descriptions.
  # Descriptions populate Hyprland's bind table description field,
  # which the shortcuts-viewer surfaces in its HTML cheat-sheet
  # (the raw "__lua <ref>" handler/arg pair is meaningless to humans).
  mkBind = key: dispatcher: desc:
    { _args = [ key dispatcher { description = desc; } ]; };
  mkBindOpts = key: dispatcher: opts: desc:
    { _args = [ key dispatcher (opts // { description = desc; }) ]; };

  # Build one workspace/move pair for SUPER+<n> / SUPER+SHIFT+<n>.
  workspaceBinds = lib.concatMap
    (i:
      let key = if i == 10 then "0" else toString i; in
      [
        (mkBind "${mod} + ${key}"
          (luaInline ''hl.dsp.focus({ workspace = ${toString i} })'')
          "Workspace ${toString i}")
        (mkBind "${mod} + SHIFT + ${key}"
          (luaInline ''hl.dsp.window.move({ workspace = ${toString i} })'')
          "Move active window to workspace ${toString i}")
      ]
    )
    (lib.range 1 10);
in
[
  # Launch applications
  (mkBind "${mod} + RETURN" (luaInline ''hl.dsp.exec_cmd("${term}")'') "Open terminal")
  (mkBind "${mod} + Space" (luaInline ''hl.dsp.exec_cmd("dms ipc spotlight toggle")'') "App launcher")
  (mkBind "${mod} + E" (luaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.nautilus}")'') "Open Nautilus")
  (mkBind "${mod} + B" (luaInline ''hl.dsp.exec_cmd("hypr-browser")'') "Open default browser")
  (mkBind "${mod} + N" (luaInline ''hl.dsp.exec_cmd("dms ipc notifications toggle")'') "Toggle notifications")
  (mkBind "${mod} + SHIFT + N" (luaInline ''hl.dsp.exec_cmd("dms ipc notepad toggle")'') "Quick notes (notepad slideout)")
  (mkBind "${mod} + D" (luaInline ''hl.dsp.exec_cmd("dms ipc dash toggle")'') "Dashboard (DankDash)")
  (mkBind "${mod} + I" (luaInline ''hl.dsp.exec_cmd("dms ipc control-center toggle")'') "Control center (network)")
  (mkBind "${mod} + C" (luaInline ''hl.dsp.exec_cmd("dms ipc clipboard toggle")'') "Clipboard history")
  (mkBind "${mod} + period" (luaInline ''hl.dsp.exec_cmd("dms ipc spotlight toggleQuery \":e \"")'') "Emoji + unicode picker")

  # Window management
  (mkBind "${mod} + Q" (luaInline "hl.dsp.window.close()") "Close active window")
  (mkBind "${mod} + SHIFT + Q" (luaInline "hl.dsp.exit()") "Exit Hyprland")
  (mkBind "${mod} + V" (luaInline ''hl.dsp.window.float({ action = "toggle" })'') "Toggle floating")
  (mkBind "${mod} + P" (luaInline ''hl.dsp.exec_cmd("dms ipc powermenu toggle")'') "Power menu")
  (mkBind "${mod} + J" (luaInline ''hl.dsp.layout("togglesplit")'') "Toggle split direction")
  (mkBind "${mod} + SHIFT + E" (luaInline ''hl.dsp.exec_cmd("hypr-equalize-windows")'') "Equalize window sizes")
  (mkBind "${mod} + SHIFT + T" (luaInline ''hl.dsp.exec_cmd("tv-workspace toggle")'') "Toggle TV: present deck ↔ mirror laptop")
  (mkBind "${mod} + F" (luaInline ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'') "Toggle fullscreen")
  (mkBind "${mod} + R" (luaInline ''hl.dsp.submap("resize")'') "Resize submap")

  # SUPER+Tab → DMS window overview/exposé (DMS's own default
  # bind). Toggles the spatial workspace grid; navigate with
  # the mouse or Left/Right, Esc to close. It is an exposé, not
  # an MRU switcher.
  (mkBind "${mod} + Tab" (luaInline ''hl.dsp.exec_cmd("dms ipc hypr toggleOverview")'') "Window overview (exposé)")

  # ALT+Tab is owned by snappy-switcher — a real MRU switcher
  # overlay bound from modules/desktop/snappy-switcher via
  # hyprflake.hyprland.extraLua. We deliberately bind no native
  # cycle_next here so a single dispatcher fires on the key.
  # (SUPER+Tab above is an exposé, not a switcher, which is why
  # snappy exists.)
]
++ [
  # Move focus
  (mkBind "${mod} + left" (luaInline ''hl.dsp.focus({ direction = "left" })'') "Focus window left")
  (mkBind "${mod} + right" (luaInline ''hl.dsp.focus({ direction = "right" })'') "Focus window right")
  (mkBind "${mod} + up" (luaInline ''hl.dsp.focus({ direction = "up" })'') "Focus window up")
  (mkBind "${mod} + down" (luaInline ''hl.dsp.focus({ direction = "down" })'') "Focus window down")

  # Move windows
  (mkBind "${mod} + SHIFT + left" (luaInline ''hl.dsp.window.move({ direction = "left" })'') "Move active window left")
  (mkBind "${mod} + SHIFT + right" (luaInline ''hl.dsp.window.move({ direction = "right" })'') "Move active window right")
  (mkBind "${mod} + SHIFT + up" (luaInline ''hl.dsp.window.move({ direction = "up" })'') "Move active window up")
  (mkBind "${mod} + SHIFT + down" (luaInline ''hl.dsp.window.move({ direction = "down" })'') "Move active window down")

  # Preselect where the NEXT window opens (dwindle). One-shot:
  # press, then SUPER+RETURN opens the terminal on that side.
  (mkBind "${mod} + ALT + left" (luaInline ''hl.dsp.layout("preselect l")'') "Next window opens left")
  (mkBind "${mod} + ALT + right" (luaInline ''hl.dsp.layout("preselect r")'') "Next window opens right")
  (mkBind "${mod} + ALT + up" (luaInline ''hl.dsp.layout("preselect u")'') "Next window opens above")
  (mkBind "${mod} + ALT + down" (luaInline ''hl.dsp.layout("preselect d")'') "Next window opens below")

  # Special workspace (scratchpad)
  (mkBind "${mod} + S" (luaInline ''hl.dsp.workspace.toggle_special("magic")'') "Toggle magic scratchpad")
  (mkBind "${mod} + SHIFT + S" (luaInline ''hl.dsp.window.move({ workspace = "special:magic" })'') "Move active window to magic scratchpad")

  # Scroll through workspaces
  (mkBind "${mod} + mouse_down" (luaInline ''hl.dsp.focus({ workspace = "e+1" })'') "Next workspace (mousewheel)")
  (mkBind "${mod} + mouse_up" (luaInline ''hl.dsp.focus({ workspace = "e-1" })'') "Previous workspace (mousewheel)")

  # Screenshots (hypr-screenshot: hyprshot + satty; see scripts.nix)
  (mkBind "Print" (luaInline ''hl.dsp.exec_cmd("hypr-screenshot region")'') "Region screenshot → satty")
  (mkBind "CTRL + ALT + P" (luaInline ''hl.dsp.exec_cmd("hypr-screenshot clip")'') "Region screenshot → clipboard")
  (mkBind "CTRL + ALT + SHIFT + P" (luaInline ''hl.dsp.exec_cmd("hypr-screenshot region")'') "Region screenshot → satty")
  (mkBind "SHIFT + Print" (luaInline ''hl.dsp.exec_cmd("hypr-screenshot output")'') "Full-output screenshot → satty")

  # Screen recording
  (mkBind "CTRL + ALT + R" (luaInline ''hl.dsp.exec_cmd("hypr-record-region")'') "Toggle region screen recording")

  # Lock screen (DMS; loginctl lock-session also triggers it
  # via loginctlLockIntegration)
  (mkBind "${mod} + L" (luaInline ''hl.dsp.exec_cmd("dms ipc lock lock")'') "Lock screen")

  # Media control via DankMaterialShell MPRIS IPC
  (mkBind "XF86AudioPlay" (luaInline ''hl.dsp.exec_cmd("dms ipc mpris playPause")'') "Media play/pause")
  (mkBind "XF86AudioPause" (luaInline ''hl.dsp.exec_cmd("dms ipc mpris playPause")'') "Media play/pause")
  (mkBind "XF86AudioNext" (luaInline ''hl.dsp.exec_cmd("dms ipc mpris next")'') "Media next")
  (mkBind "XF86AudioPrev" (luaInline ''hl.dsp.exec_cmd("dms ipc mpris previous")'') "Media previous")

  # Screen color picker (DMS; copies hex to clipboard) — replaces hyprpicker
  (mkBind "${mod} + SHIFT + C" (luaInline ''hl.dsp.exec_cmd("dms ipc color-picker toggle")'') "Pick screen color")

  # Mouse drag/resize. Keyspecs starting with `mouse:` are
  # internally treated as mouse binds; no extra flag needed.
  (mkBind "${mod} + mouse:272" (luaInline "hl.dsp.window.drag()") "Drag window (mouse)")
  (mkBind "${mod} + mouse:273" (luaInline "hl.dsp.window.resize()") "Resize window (mouse)")

  # Repeatable + locked: volume / brightness (DMS IPC).
  # The trailing "" on brightness is the device-name arg
  # (empty = preferred device).
  (mkBindOpts "XF86AudioRaiseVolume" (luaInline ''hl.dsp.exec_cmd("dms ipc audio increment 3")'') { locked = true; repeating = true; } "Volume up")
  (mkBindOpts "XF86AudioLowerVolume" (luaInline ''hl.dsp.exec_cmd("dms ipc audio decrement 3")'') { locked = true; repeating = true; } "Volume down")
  (mkBindOpts "XF86MonBrightnessUp" (luaInline ''hl.dsp.exec_cmd("dms ipc brightness increment 5 \"\"")'') { locked = true; repeating = true; } "Brightness up")
  (mkBindOpts "XF86MonBrightnessDown" (luaInline ''hl.dsp.exec_cmd("dms ipc brightness decrement 5 \"\"")'') { locked = true; repeating = true; } "Brightness down")

  # Locked: audio mute toggles
  (mkBindOpts "XF86AudioMute" (luaInline ''hl.dsp.exec_cmd("dms ipc audio mute")'') { locked = true; } "Toggle audio mute")
  (mkBindOpts "XF86AudioMicMute" (luaInline ''hl.dsp.exec_cmd("dms ipc audio micmute")'') { locked = true; } "Toggle mic mute")
] ++ workspaceBinds
