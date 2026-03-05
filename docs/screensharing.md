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

## Troubleshooting: Chrome Only Shows Tab Sharing

If Chrome only offers "Chrome Tab" sharing (no "Entire Screen" or "Window" options), the PipeWire screen capture backend isn't connecting to the XDG Desktop Portal.

### Verify PipeWire is running

```sh
systemctl --user status pipewire
```

If inactive, check that `services.pipewire.enable = true` is set in your NixOS config. hyprflake enables this by default.

### Verify the portal is running

```sh
systemctl --user status xdg-desktop-portal-hyprland
```

If inactive, restart it:

```sh
systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal
```

### Check the Chrome PipeWire flag

Visit `chrome://flags/#enable-webrtc-pipewire-capturer` in Chrome. It should be "Enabled" or "Default" (enabled by default since Chrome 110). If it's disabled, set it to "Enabled" and relaunch Chrome.

### Nuclear option: restart everything

```sh
systemctl --user restart pipewire xdg-desktop-portal-hyprland xdg-desktop-portal
```

Then fully quit and relaunch Chrome.

## Reference

https://www.ssp.sh/brain/screen-sharing-on-wayland-hyprland-with-chrome/
