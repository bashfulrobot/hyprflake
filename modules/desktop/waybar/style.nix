{ config }:

''
  * {
    font-family: "${config.stylix.fonts.monospace.name}";
    font-size: 11px;
    margin: 0px;
    padding: 0px;
  }

  window#waybar {
    background: rgba(30, 30, 46, 0.85);
    border-radius: 0 0 4px 4px;
  }

  tooltip {
    background: @base01;
    color: @base05;
    border: 1px solid @base03;
    border-radius: 8px;
    padding: 10px 12px;
    font-size: 14px;
  }

  tooltip calendar {
    font-size: 16px;
    padding: 8px;
  }

  .modules-left, .modules-center, .modules-right {
    background: transparent;
    padding: 0 15px;
  }

  #workspaces {
    margin: 0;
    padding: 0;
  }

  #idle_inhibitor, #clock, #bluetooth, #pulseaudio, #battery, #battery.alert, #tray, #custom-notification, #network {
    padding: 0 10px;
    margin: 0 1.5px;
    font-size: 20px;
  }

  #workspaces button {
    padding: 4px;
    margin: 0 2px;
    min-width: 20px;
    min-height: 20px;
    border-radius: 4px;
    color: @base04;
    background-color: transparent;
    transition: all 0.2s ease-in-out;
    font-size: 16px;
    line-height: 20px;
  }

  #workspaces button:hover {
    background-color: @base02;
    color: @base05;
  }

  #workspaces button.active,
  #workspaces button.focused {
    background-color: @base0D;
    color: @base00;
    font-weight: bold;
  }

  #workspaces button.occupied {
    color: @base05;
    background-color: @base01;
  }

  #workspaces button.urgent {
    background-color: @base08;
    color: @base00;
    font-weight: bold;
  }

  #clock {
    color: @base0D;
    font-weight: 500;
    font-size: 16px;
  }

  #battery {
    color: @base05;
  }

  #battery.critical {
    color: @base08;
    font-weight: bold;
  }

  #battery.charging {
    color: @base0D;
  }

  #battery.alert {
    font-size: 20px;
  }

  #battery.alert.warning,
  #battery.alert.critical {
    color: @base08;
    font-weight: bold;
  }

  #pulseaudio {
    color: @base0E;
    font-size: 24px;
  }

  #bluetooth {
    color: @base0D;
  }

  #network {
    color: @base0C;
  }

  #network.disconnected {
    color: @base08;
  }

  #network.ethernet {
    color: @base0B;
  }

  #tray {
    color: @base05;
  }

  #custom-notification {
    color: @base05;
  }

  #custom-system-gear {
    color: @base05;
    font-size: 26px;
  }

  #custom-power {
    color: @base0D;
    padding: 2px 8px;
    font-size: 18px;
  }
''
