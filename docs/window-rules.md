# Hyprland Window Rules Guide

Window rules in Hyprland let you set behaviors (float, opacity, pin, etc.) for
windows matching specific criteria. Hyprflake now ships with the Lua config
backend (`configType = "lua"`), so the format here is **Lua**, not hyprlang.

## Lua syntax

A window rule is a single `hl.window_rule({...})` call. Fields:

| Field          | Type   | Notes                                                      |
| -------------- | ------ | ---------------------------------------------------------- |
| `name`         | string | Optional. Required if you want to disable/re-apply later.  |
| `match`        | table  | Matcher fields like `class`, `title`, `workspace`.         |
| `enabled`      | bool   | Defaults to `true`.                                        |
| `<effect>`     | varies | Any effect: `opacity`, `float`, `pin`, `tile`, `move`, `size`, `no_focus`, … |

```lua
hl.window_rule({
  name = "float-pip",
  match = { title = "Picture-in-Picture" },
  float = true,
  pin = true,
})
```

### Regex notes

- Regexes must **fully match** the window value (since Hyprland 0.46). `tty`
  will not match `kitty` — use `.*tty.*` or just `kitty`.
- Pipe `|` works for alternation: `match = { class = "code|codium" }`.
- Prefix with `negative:` to negate: `match = { class = "negative:kitty" }`.

## Effect-value reference

| Effect  | Type   | Example                              | Notes                                  |
| ------- | ------ | ------------------------------------ | -------------------------------------- |
| opacity | string | `opacity = "0.9 0.9"`                | `"active inactive"` as one string      |
| float   | bool   | `float = true`                       | `true`/`false` (not `"on"`/`"off"`)    |
| pin     | bool   | `pin = true`                         | Keeps window above others              |
| tile    | bool   | `tile = true`                        | Force tile a floating-by-default app   |
| move    | string | `move = "100 100"`                   | Position in pixels                     |
| size    | string | `size = "800 600"`                   | Window dimensions                      |
| no_focus| bool   | `no_focus = true`                    |                                        |

The full effect list is registered in the Hyprland source under
`WINDOW_RULE_EFFECT_DESCS` (see
`src/config/lua/bindings/LuaBindingsInternal.cpp`).

## Writing rules in Nix

Window rules live in `extraConfig` (not `settings.window_rule`) so that
consumers can freely combine multiple modules without merge conflicts at the
attrset level. Each rule is one `hl.window_rule({...})` Lua call.

### Inline rules with Nix interpolation

```nix
wayland.windowManager.hyprland.extraConfig = ''
  hl.window_rule({
    name = "opacity-editors",
    match = { class = "code|codium" },
    opacity = "${toString opacity} ${toString opacity}",
  })
  hl.window_rule({
    name = "float-pip",
    match = { title = "Picture-in-Picture" },
    float = true,
  })
'';
```

### Per-app rules from a downstream module

Declare a `.lua` snippet through the `hyprflake.hyprland.extraLua` option (an
attribute set of module name to Lua path or string). Hyprflake writes it under
`~/.config/hypr` and `require`s it at the end of `hyprland.lua`:

```nix
hyprflake.hyprland.extraLua."morgen-windowrule" = ''
  hl.window_rule({
    name = "morgen-tile",
    match = { class = "^([Mm]orgen)$" },
    tile = true,
  })
'';
```

See "Extra Lua modules" in `docs/architecture.md` for the full mechanism. Files
dropped directly into `~/.config/hypr/conf.d/` are no longer loaded.

## Upstream reference

- [Hyprland Window Rules Wiki](https://wiki.hypr.land/Configuring/Window-Rules/)
- Hyprland source: `src/config/lua/bindings/LuaBindingsConfigRules.cpp` (`hlWindowRule`)
