{ config }: ''
  /* SwayNC Styling - Stylix Base16 Theme */
  /* All colors use @base00-@base0F variables defined by Stylix */

  * {
    all: unset;
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  /* Control Center Window */
  .control-center {
    background: @base00;
    color: @base05;
    border: 2px solid @base0D;
    border-left-width: 6px;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3), -6px 0 12px rgba(0, 0, 0, 0.4);
  }

  .control-center-list {
    background: transparent;
  }

  /* Notification Background Wrapper */
  .notification-background {
    background: transparent;
    margin: 0;
    padding: 0;
  }

  .notification-background .notification {
    background: @base00;
    color: @base05;
    border: 2px solid @base0D;
    border-left-width: 6px;
    border-radius: 8px;
    margin: 6px;
    padding: 0;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2), -4px 0 8px rgba(0, 0, 0, 0.3);
  }

  .notification-content {
    background: transparent;
    padding: 8px;
    margin: 0;
  }

  /* Notification Text */
  .summary {
    font-weight: bold;
    color: @base05;
  }

  .body {
    color: @base04;
  }

  .time {
    color: @base04;
  }

  .image {
    margin: 8px;
  }

  /* Notification Action Buttons */
  .notification-action {
    background: @base01;
    color: @base05;
    border-radius: 6px;
    padding: 6px 12px;
    margin: 4px;
    border: 1px solid @base03;
  }

  .notification-action:hover {
    background: @base02;
    color: @base05;
  }

  .notification-action:active {
    background: @base0D;
    color: @base00;
  }

  /* Close Button */
  .close-button {
    background: @base01;
    color: @base05;
    border-radius: 4px;
    padding: 4px 6px;
    margin: 4px;
    min-width: 16px;
    min-height: 16px;
    transition: all 200ms ease;
  }

  .close-button:hover {
    background: @base08;
    color: @base00;
  }

  .close-button:active {
    background: @base08;
  }

  /* Urgency Levels */
  .notification.low {
    border-left: 3px solid @base0B;
  }

  .notification.normal {
    border-left: 3px solid @base0D;
  }

  .notification.critical {
    border-left: 3px solid @base08;
    background: @base01;
  }

  /* Widget Title (Notifications header) */
  .widget-title {
    background: transparent;
    color: @base05;
    margin: 8px;
    padding: 8px 8px 4px 8px;
    border-bottom: 1px solid @base03;
    font-weight: bold;
  }

  .widget-title > button {
    background: @base01;
    color: @base0D;
    border-radius: 6px;
    padding: 6px 12px;
    font-weight: 500;
    transition: all 200ms ease;
    border: 1px solid @base0D;
  }

  .widget-title > button:hover {
    background: @base0D;
    color: @base00;
  }

  .widget-title > button:active {
    background: @base0D;
  }

  /* DND Toggle Widget */
  .widget-dnd {
    background: transparent;
    color: @base05;
    margin: 8px;
    padding: 8px;
    border-radius: 6px;
  }

  .widget-dnd > label {
    font-weight: 500;
  }

  /* Switch (DND Toggle) */
  switch {
    background: @base01;
    border-radius: 16px;
    min-width: 48px;
    min-height: 24px;
    border: 1px solid @base03;
  }

  switch:checked {
    background: @base0D;
    border-color: @base0D;
  }

  switch slider {
    background: @base05;
    border-radius: 50%;
    min-width: 20px;
    min-height: 20px;
    margin: 2px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
  }

  switch:checked slider {
    background: @base00;
  }

  /* MPRIS Media Player Widget */
  .widget-mpris {
    background: @base01;
    color: @base05;
    margin: 8px;
    padding: 12px;
    border-radius: 8px;
    border: 1px solid @base03;
  }

  .widget-mpris-player {
    background: transparent;
    padding: 8px 0;
    border-radius: 4px;
  }

  .widget-mpris-title {
    font-weight: bold;
    color: @base05;
  }

  .widget-mpris-subtitle {
    color: @base04;
    font-size: ${toString (config.stylix.fonts.sizes.applications - 2)}px;
  }

  .widget-mpris > box > button {
    background: transparent;
    color: @base05;
    border-radius: 6px;
    padding: 8px 12px;
    margin: 2px;
    transition: all 200ms ease;
  }

  .widget-mpris > box > button:hover {
    background: @base02;
    color: @base0D;
  }

  .widget-mpris > box > button:active {
    background: @base02;
  }

  .widget-mpris > box > button:disabled {
    opacity: 0.5;
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
    background: @base01;
    border-radius: 8px;
    min-width: 8px;
    min-height: 40px;
    border: 1px solid @base03;
  }

  scrollbar slider:hover {
    background: @base02;
  }

  scrollbar slider:active {
    background: @base0D;
  }

  /* Notification Group */
  .notification-group {
    background: transparent;
  }

  .notification-group .notification-group-buttons,
  .notification-group .notification-group-headers {
    color: @base05;
  }

  .notification-group.collapsed .notification-row .notification {
    background: @base01;
  }

  .notification-group.collapsed:hover .notification-row:not(:only-child) .notification {
    background: @base01;
  }
''
