{ config }: ''
  /* Wlogout styling with Stylix base16 color integration */

  * {
    background-image: none;
    box-shadow: none;
  }

  window {
    background-color: rgba(0, 0, 0, ${toString config.stylix.opacity.popups});
  }

  button {
    color: @theme_text_color;
    background-color: @surface0;
    border-style: solid;
    border-width: 2px;
    border-color: @surface2;
    border-radius: 12px;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
    margin: 20px;
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  button:focus,
  button:active,
  button:hover {
    background-color: @accent_bg_color;
    color: @accent_fg_color;
    background-size: 20%;
    border-color: @accent_color;
    outline-style: none;
  }

  #logout {
    background-image: image(url("/run/current-system/sw/share/wlogout/icons/logout.png"));
  }

  #suspend {
    background-image: image(url("/run/current-system/sw/share/wlogout/icons/suspend.png"));
  }

  #shutdown {
    background-image: image(url("/run/current-system/sw/share/wlogout/icons/shutdown.png"));
  }

  #reboot {
    background-image: image(url("/run/current-system/sw/share/wlogout/icons/reboot.png"));
  }
''
