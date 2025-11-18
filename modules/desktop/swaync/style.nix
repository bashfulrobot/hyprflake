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
    background: @theme_bg_color;
    color: @theme_text_color;
    border: 1px solid @surface0;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
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
    background: transparent;
    color: @theme_text_color;
    margin: 8px;
    padding: 8px 8px 4px 8px;
    border-bottom: 1px solid @surface0;
    font-weight: bold;
  }

  .widget-title > button {
    background: @surface0;
    color: @blue;
    border-radius: 6px;
    padding: 6px 12px;
    font-weight: 500;
    transition: all 200ms ease;
  }

  .widget-title > button:hover {
    background: @blue;
    color: @theme_bg_color;
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

  .widget-dnd > switch {
    background: @surface1;
    border-radius: 16px;
    min-width: 48px;
    min-height: 24px;
    padding: 0;
    transition: all 200ms ease;
  }

  .widget-dnd > switch:checked {
    background: @blue;
  }

  .widget-dnd > switch slider {
    background: @theme_bg_color;
    border-radius: 50%;
    min-width: 20px;
    min-height: 20px;
    margin: 2px;
    transition: all 200ms ease;
  }

  /* Close button */
  .close-button {
    background: transparent;
    color: @overlay1;
    border-radius: 4px;
    padding: 4px;
    margin: 4px;
    transition: all 200ms ease;
  }

  .close-button:hover {
    background: @red;
    color: @theme_bg_color;
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
    padding: 12px;
    border-radius: 8px;
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
    background: @surface1;
    color: @blue;
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
