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
    padding: 4px 8px;
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
    padding: 4px 8px;
    margin: 0 2px;
    border-radius: 4px;
    color: @base04;
    background-color: transparent;
    transition: all 0.2s ease-in-out;
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
    color: @base0A;
    font-weight: 500;
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

  #pulseaudio {
    color: @base0E;
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

  #custom-power {
    color: @base08;
    padding: 2px 8px;
  }
''
