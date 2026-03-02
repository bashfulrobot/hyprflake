# Hyprland Window Rules Guide

Window rules in Hyprland let you set behaviors (float, opacity, pin, etc.) for
windows matching specific criteria. The syntax has changed across versions, so
this document captures the current correct format.

## Current Syntax (Hyprland 0.53+)

Hyprland 0.53 overhauled the windowrule syntax. The old `windowrulev2` keyword
is gone and `windowrule` now uses `match:` prefixed fields.

### Key differences from pre-0.53

| Change | Old | New |
|---|---|---|
| Match by class | `class:kitty` | `match:class kitty` |
| Match by title | `title:Firefox` | `match:title Firefox` |
| Boolean rules | `float` | `float on` |
| Keyword | `windowrulev2` | `windowrule` |

### Inline (anonymous) rules

```
windowrule = RULE VALUE, match:FIELD REGEX
```

Match and rule can appear in either order. Examples:

```
windowrule = opacity 0.9 0.9, match:class kitty
windowrule = float on, match:class pavucontrol
windowrule = pin on, match:title Picture-in-Picture
```

### Block (named) rules

Named rules group multiple effects under one matcher. They use `=` instead of
spaces between field and value:

```
windowrule {
    name = my-rule-name
    match:class = ^(org\.gnome\.)
    rounding = 12
    no_border = on
}
```

### Regex notes

- Regexes must **fully match** the window value (since Hyprland 0.46).
  `tty` will not match `kitty` — use `.*tty.*` or just `kitty`.
- Pipe `|` works for alternation: `match:class code|codium`
- Prefix with `negative:` to negate: `match:class negative:kitty`

## Writing rules in Nix

Window rules live in `extraConfig` (not `settings.windowrule`) so that
consumers can freely set `windowrule` in their own configs without merge
conflicts.

### Inline rules with interpolation

```nix
extraConfig = ''
  windowrule = opacity ${toString opacity} ${toString opacity}, match:class kitty
  windowrule = float on, match:class pavucontrol|blueman-manager
'';
```

### Block rules in settings

For block-style named rules, use `wayland.windowManager.hyprland.settings`:

```nix
settings.windowrule = [
  {
    name = "my-rule";
    "match:class" = "^(org\\.gnome\\.)";
    rounding = 12;
  }
];
```

## Common rule reference

| Rule | Example | Notes |
|---|---|---|
| `opacity A I` | `opacity 0.9 0.8` | Active and inactive opacity |
| `float on` | `float on` | Must include `on` |
| `pin on` | `pin on` | Keeps window above others |
| `tile on` | `tile on` | Force tile a window |
| `move X Y` | `move 100 100` | Position in pixels |
| `size W H` | `size 800 600` | Window dimensions |
| `workspace N` | `workspace 2` | Send to workspace |

## Upstream reference

- [Hyprland Window Rules Wiki](https://wiki.hypr.land/Configuring/Window-Rules/)
