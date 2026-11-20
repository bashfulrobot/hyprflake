# Lua appended verbatim after the structured hl.* calls: window rules and the resize submap.
{ osConfig, termCfg }:

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

    -- Exit
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("return", hl.dsp.submap("reset"))
  end)
''
