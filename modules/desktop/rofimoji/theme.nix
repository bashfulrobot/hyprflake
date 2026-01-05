{ config }: ''
  /**
   * Rofimoji Theme - Stylix Integration
   * Matches the main rofi launcher styling
   * Optimized for emoji and character selection with grid layout
   **/

  * {
      background:     #${config.lib.stylix.colors.base00}FF;
      background-alt: #${config.lib.stylix.colors.base01}FF;
      foreground:     #${config.lib.stylix.colors.base05}FF;
      selected:       #${config.lib.stylix.colors.base0D}FF;
      active:         #${config.lib.stylix.colors.base0B}FF;
      urgent:         #${config.lib.stylix.colors.base08}FF;
      border-color:   #${config.lib.stylix.colors.base0D}FF;  /* Active window border color */
  }

  window {
      transparency:                "real";
      location:                    center;
      anchor:                      center;
      fullscreen:                  false;
      width:                       800px;
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
      children:                    [ "inputbar", "listview" ];
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
      placeholder:                 "Search emoji...";
      placeholder-color:           inherit;
  }

  listview {
      enabled:                     true;
      columns:                     8;
      lines:                       6;
      cycle:                       true;
      dynamic:                     true;
      scrollbar:                   false;
      layout:                      vertical;
      reverse:                     false;
      fixed-height:                true;
      fixed-columns:               true;
      spacing:                     8px;
      background-color:            transparent;
      text-color:                  @foreground;
      cursor:                      "default";
  }

  element {
      enabled:                     true;
      spacing:                     0px;
      padding:                     15px;
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
      horizontal-align:            0.5;
  }
''
