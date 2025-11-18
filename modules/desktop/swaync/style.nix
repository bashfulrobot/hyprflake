{ config }: ''
  /* SwayNC Minimal Styling - Stylix Themed */
  /* Uses GTK color variables that automatically update with theme changes */

  * {
    all: unset;
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  /* Control Center */
  .control-center {
    background: @theme_base_color;
    color: @theme_text_color;
    border: 1px solid @surface1;
    border-radius: 8px;
  }

  .control-center-list {
    background: transparent;
  }

  /* Notification window */
  .notification {
    background: @theme_bg_color;
    color: @theme_text_color;
    border: 1px solid @surface1;
    border-radius: 8px;
    margin: 6px;
    padding: 0;
  }

  .notification-content {
    background: transparent;
    padding: 8px;
  }

  /* Notification summary (title) */
  .summary {
    font-weight: bold;
    color: @theme_text_color;
  }

  /* Notification body text */
  .body {
    color: @subtext0;
  }

  /* Widget title */
  .widget-title {
    background: @surface0;
    color: @theme_text_color;
    margin: 8px;
    padding: 8px;
    border-radius: 4px;
    font-weight: bold;
  }

  .widget-title > button {
    background: @blue;
    color: @theme_base_color;
    border-radius: 4px;
    padding: 4px 8px;
  }

  .widget-title > button:hover {
    background: @lavender;
  }

  /* DND toggle */
  .widget-dnd {
    background: @surface0;
    color: @theme_text_color;
    margin: 8px;
    padding: 8px;
    border-radius: 4px;
  }

  .widget-dnd > switch {
    background: @surface1;
    border-radius: 12px;
    padding: 2px;
  }

  .widget-dnd > switch:checked {
    background: @blue;
  }

  /* Close button */
  .close-button {
    background: @red;
    color: @theme_base_color;
    border-radius: 4px;
    padding: 4px;
    margin: 4px;
  }

  .close-button:hover {
    background: @maroon;
  }

  /* Urgency levels */
  .notification.low {
    border-left: 3px solid @green;
  }

  .notification.normal {
    border-left: 3px solid @blue;
  }

  .notification.critical {
    border-left: 3px solid @red;
    background: @surface0;
  }

  /* MPRIS (Media Player) Widget */
  .widget-mpris {
    background: @surface0;
    color: @theme_text_color;
    margin: 8px;
    padding: 8px;
    border-radius: 8px;
  }

  .widget-mpris > box > button {
    background: @surface1;
    color: @theme_text_color;
    border-radius: 4px;
    padding: 4px 8px;
    margin: 2px;
  }

  .widget-mpris > box > button:hover {
    background: @blue;
    color: @theme_base_color;
  }

  .widget-mpris-player {
    background: @surface1;
    padding: 8px;
    border-radius: 4px;
  }

  .widget-mpris-title {
    font-weight: bold;
    color: @theme_text_color;
  }

  .widget-mpris-subtitle {
    color: @subtext0;
    font-size: ${toString (config.stylix.fonts.sizes.applications - 2)}px;
  }

  /* Scrollbar */
  scrollbar {
    background: transparent;
  }

  scrollbar slider {
    background: @surface1;
    border-radius: 8px;
  }

  scrollbar slider:hover {
    background: @surface2;
  }
''
