{ config }: ''
  /* Calendar Takeover - Stylix Base16 Theme */
  /* Fullscreen overlay triggered by swaync for matching calendar notifications */

  * {
    font-family: "${config.stylix.fonts.sansSerif.name}";
    color: @base05;
  }

  window.calendar-takeover {
    background: alpha(@base00, 0.92);
  }

  .calendar-takeover .content {
    padding: 48px 64px;
    min-width: 560px;
    background: @base01;
    border: 2px solid @base0D;
    border-radius: 16px;
    box-shadow: 0 16px 48px rgba(0, 0, 0, 0.6);
  }

  .calendar-takeover .summary {
    font-size: ${toString (config.stylix.fonts.sizes.applications * 3)}px;
    font-weight: bold;
    color: @base05;
  }

  .calendar-takeover .body {
    font-size: ${toString (config.stylix.fonts.sizes.applications * 2)}px;
    color: @base04;
    margin-top: 8px;
  }

  .calendar-takeover button.dismiss {
    margin-top: 16px;
    padding: 16px 40px;
    font-size: ${toString (config.stylix.fonts.sizes.applications + 4)}px;
    font-weight: 600;
    background: @base0D;
    color: @base00;
    border: none;
    border-radius: 10px;
    min-width: 200px;
  }

  .calendar-takeover button.dismiss:hover {
    background: @base0C;
  }

  .calendar-takeover button.dismiss:active {
    background: @base0E;
  }

  .calendar-takeover button.dismiss:focus {
    outline: 2px solid @base0A;
    outline-offset: 4px;
  }
''
