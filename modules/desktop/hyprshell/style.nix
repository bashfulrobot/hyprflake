{ config }: ''
  /* Hyprshell CSS Styling - Stylix Integration
   * Active window border matches Hyprland active window border
   * Inactive borders match Hyprland inactive window border
   */

  /* Active window border - matches Hyprland active window */
  .window.selected {
    border: 2px solid @accent_color;
  }

  /* Inactive/external window borders - matches Hyprland inactive window */
  .window {
    border: 2px solid @theme_unfocused_border_color;
  }

  /* Additional styling to ensure consistency */
  .window-box {
    border-color: @theme_unfocused_border_color;
  }

  .window-box.selected {
    border-color: @accent_color;
  }
''
