{ config }: ''
  /**
   * rofi-network-manager Theme - Stylix Integration
   * Matches the main rofi launcher styling
   **/

  * {
      background:     #${config.lib.stylix.colors.base00}FF;
      background-alt: #${config.lib.stylix.colors.base01}FF;
      foreground:     #${config.lib.stylix.colors.base05}FF;
      selected:       #${config.lib.stylix.colors.base0D}FF;
      active:         #${config.lib.stylix.colors.base0B}FF;
      urgent:         #${config.lib.stylix.colors.base08}FF;
      border-color:   #${config.lib.stylix.colors.base03}FF;
  }

  window {
      transparency:                "real";
      location:                    center;
      anchor:                      center;
      fullscreen:                  false;
      width:                       600px;
      border:                      2px solid;
      border-radius:               12px;
      border-color:                @border-color;
      background-color:            @background;
      cursor:                      "default";
  }

  mainbox {
      enabled:                     true;
      spacing:                     10px;
      margin:                      0px;
      padding:                     20px;
      background-color:            @background;
      children:                    [ "inputbar", "message", "listview" ];
  }

  inputbar {
      enabled:                     true;
      spacing:                     10px;
      padding:                     15px;
      border-radius:               10px;
      background-color:            @background-alt;
      text-color:                  @foreground;
      children:                    [ "prompt", "entry" ];
  }

  prompt {
      enabled:                     true;
      background-color:            transparent;
      text-color:                  inherit;
  }

  entry {
      enabled:                     true;
      background-color:            transparent;
      text-color:                  inherit;
      cursor:                      text;
      placeholder:                 "Search";
      placeholder-color:           inherit;
  }

  message {
      enabled:                     true;
      padding:                     10px;
      border-radius:               10px;
      background-color:            @background-alt;
      text-color:                  @foreground;
  }

  textbox {
      background-color:            transparent;
      text-color:                  inherit;
      vertical-align:              0.5;
      horizontal-align:            0.0;
  }

  listview {
      enabled:                     true;
      columns:                     1;
      lines:                       8;
      cycle:                       true;
      dynamic:                     true;
      scrollbar:                   false;
      layout:                      vertical;
      reverse:                     false;
      fixed-height:                true;
      fixed-columns:               true;
      spacing:                     5px;
      background-color:            transparent;
      text-color:                  @foreground;
      cursor:                      "default";
  }

  element {
      enabled:                     true;
      spacing:                     10px;
      padding:                     10px;
      border-radius:               8px;
      background-color:            transparent;
      text-color:                  @foreground;
      cursor:                      pointer;
  }

  element normal.normal {
      background-color:            transparent;
      text-color:                  @foreground;
  }

  element selected.normal {
      background-color:            @selected;
      text-color:                  @background;
  }

  element-text {
      background-color:            transparent;
      text-color:                  inherit;
      cursor:                      inherit;
      vertical-align:              0.5;
      horizontal-align:            0.0;
  }
''
