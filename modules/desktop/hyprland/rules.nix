# Lua appended verbatim after the structured hl.* calls: window rules and the resize submap.
{ lib, pkgs, osConfig, termCfg }:

''
  -- ===== window rules =====
  -- `hl.window_rule({name=..., match={...}, <effect>=<value>})`.
  -- opacity is a STRING ("active inactive"), tile is a bool.
  hl.window_rule({
    name = "opacity-editors",
    match = { class = "code|codium" },
    opacity = "${toString osConfig.hyprflake.style.opacity.applications} ${toString osConfig.hyprflake.style.opacity.applications}",
  })
  hl.window_rule({
    name = "opacity-browsers",
    match = { class = "chromium|firefox" },
    opacity = "${toString osConfig.hyprflake.style.opacity.applications} ${toString osConfig.hyprflake.style.opacity.applications}",
  })
  hl.window_rule({
    name = "opacity-terminal",
    match = { class = "${termCfg.name}" },
    opacity = "${toString osConfig.hyprflake.style.opacity.terminal} ${toString osConfig.hyprflake.style.opacity.terminal}",
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

  -- ===== dialogs =====
  -- File chooser portal and polkit prompts open as tiles by default; float
  -- and center them so they read as dialogs. The polkit agent also keeps
  -- focus so a password prompt cannot be typed into the window behind it.
  hl.window_rule({
    name = "float-portal-dialogs",
    match = { class = "xdg-desktop-portal-gtk" },
    float = true,
    center = true,
    size = "900 600",
  })
  hl.window_rule({
    name = "float-polkit",
    match = { class = ".*polkit.*" },
    float = true,
    center = true,
    stay_focused = true,
  })

  -- slurp's region selector (screenshots, recording) should appear at once,
  -- not fade in under the cursor.
  hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
  })
  ${lib.optionalString osConfig.hyprflake.desktop.hyprland.idleInhibitFullscreen ''
  -- ===== idle inhibit =====
  -- Any fullscreen window keeps the session awake (no idle lock, no screen
  -- off). Toggle with hyprflake.desktop.hyprland.idleInhibitFullscreen.
  hl.window_rule({
    name = "idle-inhibit-fullscreen",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
  })
  ''}
  -- ===== resize submap =====
  -- Inside `hl.define_submap`, hl.bind() is auto-scoped to the
  -- submap. `repeating = true` reproduces the old `binde`.
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

    -- Hold SHIFT for 4x bigger steps
    hl.bind("SHIFT + h", hl.dsp.window.resize({ x = -200, y = 0,    relative = true }), { repeating = true })
    hl.bind("SHIFT + l", hl.dsp.window.resize({ x = 200,  y = 0,    relative = true }), { repeating = true })
    hl.bind("SHIFT + k", hl.dsp.window.resize({ x = 0,    y = -200, relative = true }), { repeating = true })
    hl.bind("SHIFT + j", hl.dsp.window.resize({ x = 0,    y = 200,  relative = true }), { repeating = true })
    hl.bind("SHIFT + left",  hl.dsp.window.resize({ x = -200, y = 0,    relative = true }), { repeating = true })
    hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 200,  y = 0,    relative = true }), { repeating = true })
    hl.bind("SHIFT + up",    hl.dsp.window.resize({ x = 0,    y = -200, relative = true }), { repeating = true })
    hl.bind("SHIFT + down",  hl.dsp.window.resize({ x = 0,    y = 200,  relative = true }), { repeating = true })

    -- Exit (with a short transient toast so the mode is visible)
    local function leave_resize()
      hl.dispatch(hl.dsp.submap("reset"))
      hl.exec_cmd("${pkgs.libnotify}/bin/notify-send -a hyprland -t 1200 -h boolean:transient:true 'Resize mode off'")
    end
    hl.bind("escape", leave_resize)
    hl.bind("return", leave_resize)
  end)
''
