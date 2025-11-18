{ config }: ''
  /* SwayNC Minimal Styling - Stylix Themed */
  /* Uses GTK color variables that automatically update with theme changes */

  * {
    all: unset;
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  /* GTK Widget Resets */
  trough,
  scale,
  slider,
  progress,
  progressbar {
    all: unset;
  }

  /* Control Center */
  .control-center {
    background: @theme_bg_color;
    color: @theme_text_color;
    border: 1px solid @surface0;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  }

  .control-center-list {
    background: transparent;
  }

  /* Notification wrapper */
  .notification-background {
    background: transparent;
    margin: 0;
    padding: 0;
  }

  .notification-background .notification {
    background: @theme_bg_color;
    color: @theme_text_color;
    border: 1px solid @theme_unfocused_border_color;
    border-radius: 8px;
    margin: 6px;
    padding: 0;
  }

  .notification-content {
    background: transparent;
    padding: 8px;
    margin: 0;
  }

  /* Notification summary (title) */
  .summary {
    font-weight: bold;
    color: @theme_text_color;
  }

  /* Notification body text */
  .body {
    color: @theme_unfocused_fg_color;
  }

  /* Notification image */
  .image {
    margin: 8px;
  }

  /* Widget title */
  .widget-title {
    background: transparent;
    color: @theme_text_color;
    margin: 8px;
    padding: 8px 8px 4px 8px;
    border-bottom: 1px solid @theme_unfocused_border_color;
    font-weight: bold;
  }

  .widget-title > button {
    background: @theme_unfocused_bg_color;
    color: @accent_color;
    border-radius: 6px;
    padding: 6px 12px;
    font-weight: 500;
    transition: all 200ms ease;
  }

  .widget-title > button:hover {
    background: @accent_bg_color;
    color: @accent_fg_color;
  }

  .widget-title > button:active {
    background: @accent_bg_color;
  }

  /* DND toggle */
  .widget-dnd {
    background: transparent;
    color: @theme_text_color;
    margin: 8px;
    padding: 8px;
    border-radius: 6px;
  }

  .widget-dnd > label {
    font-weight: 500;
  }

  /* Switch widget (DND toggle) */
  switch {
    background: @theme_unfocused_bg_color;
    border-radius: 16px;
    min-width: 48px;
    min-height: 24px;
    border: 1px solid @theme_unfocused_border_color;
  }

  switch:checked {
    background: @accent_bg_color;
  }

  switch slider {
    background: @theme_bg_color;
    border-radius: 50%;
    min-width: 20px;
    min-height: 20px;
    margin: 2px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
  }

  switch:checked slider {
    background: @accent_fg_color;
  }

  /* Notification action buttons */
  .notification-action {
    background: @theme_unfocused_bg_color;
    color: @theme_text_color;
    border-radius: 6px;
    padding: 6px 12px;
    margin: 4px;
    border: 1px solid @theme_unfocused_border_color;
  }

  .notification-action:hover {
    background: @theme_selected_bg_color;
    color: @theme_selected_fg_color;
  }

  .notification-action:active {
    background: @theme_selected_bg_color;
  }

  /* Close button */
  .close-button {
    background: transparent;
    color: @theme_unfocused_fg_color;
    border-radius: 4px;
    padding: 4px;
    margin: 4px;
    transition: all 200ms ease;
  }

  .close-button:hover {
    background: @error_color;
    color: @theme_bg_color;
  }

  .close-button:active {
    background: @error_color;
  }

  /* Urgency levels */
  .notification.low {
    border-left: 3px solid @success_color;
  }

  .notification.normal {
    border-left: 3px solid @accent_bg_color;
  }

  .notification.critical {
    border-left: 3px solid @error_color;
    background: @theme_unfocused_bg_color;
  }

  /* MPRIS (Media Player) Widget */
  .widget-mpris {
    background: @theme_unfocused_bg_color;
    color: @theme_text_color;
    margin: 8px;
    padding: 12px;
    border-radius: 8px;
    border: 1px solid @theme_unfocused_border_color;
  }

  .widget-mpris > box > button {
    background: transparent;
    color: @theme_text_color;
    border-radius: 6px;
    padding: 8px 12px;
    margin: 2px;
    transition: all 200ms ease;
  }

  .widget-mpris > box > button:hover {
    background: @theme_selected_bg_color;
    color: @accent_color;
  }

  .widget-mpris > box > button:active {
    background: @theme_selected_bg_color;
  }

  .widget-mpris > box > button:disabled {
    opacity: 0.5;
  }

  .widget-mpris-player {
    background: transparent;
    padding: 8px 0;
    border-radius: 4px;
  }

  .widget-mpris-title {
    font-weight: bold;
    color: @theme_text_color;
  }

  .widget-mpris-subtitle {
    color: @theme_unfocused_fg_color;
    font-size: ${toString (config.stylix.fonts.sizes.applications - 2)}px;
  }

  /* Scrollbar */
  scrollbar {
    background: transparent;
    border: none;
  }

  scrollbar trough {
    background: transparent;
  }

  scrollbar slider {
    background: @theme_unfocused_bg_color;
    border-radius: 8px;
    min-width: 8px;
    min-height: 40px;
    border: 1px solid @theme_unfocused_border_color;
  }

  scrollbar slider:hover {
    background: @theme_selected_bg_color;
  }

  scrollbar slider:active {
    background: @accent_bg_color;
  }
''
