# Screen Sharing

## Issue

Chromium browsers (Chrome, Brave, Edge) show a double-prompt dialog when screen sharing on Hyprland. You must select your screen twice, and only the second selection matters.

## Fix

hyprflake automatically creates `~/.config/hypr/xdph.conf` with:

```conf
screencopy {
  allow_token_by_default = true
}
```

This eliminates the double-prompt and makes screen sharing work correctly on the first selection.

## Implementation

The fix is applied in `modules/desktop/hyprland/default.nix` via Home Manager:

```nix
xdg.configFile."hypr/xdph.conf".text = ''
  screencopy {
    allow_token_by_default = true
  }
'';
```

No additional configuration needed - it's automatically enabled when using hyprflake.

## Reference

https://www.ssp.sh/brain/screen-sharing-on-wayland-hyprland-with-chrome/
