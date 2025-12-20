{ config }: ''
  /* Hyprshell CSS Styling - Stylix Integration
   * Uses CSS custom properties that hyprshell expects
   * Active window border matches Hyprland active window border
   * Inactive borders match Hyprland inactive window border
   */

  :root {
    /* Border colors - match Hyprland window borders */
    --border-color: @theme_unfocused_border_color;
    --border-color-active: @accent_color;

    /* Background colors - use Stylix base colors */
    --bg-color: @theme_base_color;
    --bg-color-hover: @theme_selected_bg_color;

    /* Border styling */
    --border-radius: 8px;
    --border-size: 2px;
    --border-style: solid;

    /* Text color */
    --text-color: @theme_text_color;

    /* Window padding */
    --window-padding: 4px;
  }
''
