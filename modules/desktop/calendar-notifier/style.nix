{ config }:
let
  c = config.lib.stylix.colors;
  inherit (config.stylix) fonts;
  fontSize = fonts.sizes.applications;
in
''
  /* Calendar Takeover - Stylix Base16 Theme */
  /* Fullscreen overlay triggered by swaync for matching calendar notifications */

  /* Named colors seeded from Stylix base16 palette */
  @define-color base00 #${c.base00};
  @define-color base01 #${c.base01};
  @define-color base02 #${c.base02};
  @define-color base03 #${c.base03};
  @define-color base04 #${c.base04};
  @define-color base05 #${c.base05};
  @define-color base06 #${c.base06};
  @define-color base07 #${c.base07};
  @define-color base08 #${c.base08};
  @define-color base09 #${c.base09};
  @define-color base0A #${c.base0A};
  @define-color base0B #${c.base0B};
  @define-color base0C #${c.base0C};
  @define-color base0D #${c.base0D};
  @define-color base0E #${c.base0E};
  @define-color base0F #${c.base0F};

  * {
    font-family: "${fonts.sansSerif.name}";
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
    font-size: ${toString (fontSize * 3)}px;
    font-weight: bold;
    color: @base05;
  }

  .calendar-takeover .body {
    font-size: ${toString (fontSize + 6)}px;
    color: @base04;
    margin-top: 8px;
  }

  .calendar-takeover .body link,
  .calendar-takeover .body link:visited {
    color: @base0C;
    text-decoration: underline;
  }

  .calendar-takeover .body link:hover {
    color: @base0D;
  }

  .calendar-takeover .body selection {
    background: @base0D;
    color: @base00;
  }

  .calendar-takeover .button-row {
    margin-top: 24px;
  }

  .calendar-takeover button {
    padding: 14px 32px;
    font-size: ${toString (fontSize + 2)}px;
    font-weight: 600;
    background-image: none;
    border: none;
    border-radius: 10px;
    min-width: 160px;
    transition: background 150ms ease, color 150ms ease;
  }

  .calendar-takeover button.dismiss {
    background: @base0D;
    color: @base00;
  }

  .calendar-takeover button.dismiss:hover {
    background: @base0C;
  }

  .calendar-takeover button.dismiss:active {
    background: @base0E;
  }

  .calendar-takeover button.copy,
  .calendar-takeover button.open {
    background: @base02;
    color: @base05;
    border: 1px solid @base03;
  }

  .calendar-takeover button.copy:hover,
  .calendar-takeover button.open:hover {
    background: @base03;
    color: @base07;
  }

  .calendar-takeover button.copy:active,
  .calendar-takeover button.open:active {
    background: @base0A;
    color: @base00;
  }

  .calendar-takeover button.copy.copied {
    background: @base0B;
    color: @base00;
    border-color: @base0B;
  }

  .calendar-takeover button:focus {
    outline: 2px solid @base0A;
    outline-offset: 3px;
  }

  /* Account picker: [Dropdown ▾ | Open Calendar] as one unit */
  .calendar-takeover .account-picker > dropdown,
  .calendar-takeover .account-picker > button {
    border-radius: 0;
    margin: 0;
    min-width: 0;
  }

  .calendar-takeover .account-picker > dropdown {
    background: @base02;
    color: @base05;
    border: 1px solid @base03;
    border-right: none;
    border-top-left-radius: 10px;
    border-bottom-left-radius: 10px;
    padding: 8px 16px;
  }

  .calendar-takeover .account-picker > dropdown:hover {
    background: @base03;
  }

  .calendar-takeover .account-picker > button.open {
    border-top-right-radius: 10px;
    border-bottom-right-radius: 10px;
    border-top-left-radius: 0;
    border-bottom-left-radius: 0;
    min-width: 180px;
  }
''
