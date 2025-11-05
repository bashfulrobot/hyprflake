{ config }:

''
  * {
    font-family: "${config.stylix.fonts.monospace.name}";
    font-size: 11px;
    margin: 0px;
    padding: 0px;
  }

  window#waybar {
    background: @theme_base_color;
    border-radius: 0px;
  }

  tooltip {
    border-radius: 8px;
  }

  .modules-left, .modules-center, .modules-right {
    background: transparent;
    padding: 0 15px;
  }

  #workspaces, #idle_inhibitor, #clock, #bluetooth, #pulseaudio, #battery, #tray, #custom-notification {
    padding: 1px 10px;
    margin: 0 1.5px;
  }

  #workspaces button {
    padding: 1px 8px;
    margin: 0 1px;
    border-radius: 0px;
    background-color: transparent;
    transition: all 0.2s ease-in-out;
  }

  #workspaces button:hover {
    background-color: @surface1;
  }

  #workspaces button.active {
    background-color: @blue;
    font-weight: bold;
  }

  #clock {
    color: @yellow;
    font-weight: 500;
  }

  #battery.critical {
    color: @red;
    font-weight: bold;
  }

  #battery.charging {
    color: @blue;
  }

  #pulseaudio {
    color: @lavender;
  }

  #bluetooth {
    color: @blue;
  }

  #custom-power {
    color: @red;
    padding: 2px 8px;
  }
''
