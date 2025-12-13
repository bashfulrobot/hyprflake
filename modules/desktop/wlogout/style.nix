{ config }: ''
  /* Wlogout styling with Stylix base16 color integration */

  * {
    background-image: none;
    box-shadow: none;
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  window {
    background-color: rgba(0, 0, 0, ${toString config.stylix.opacity.popups});
  }

  button {
    /* Stylix theming */
    background-color: @surface0;
    color: @theme_text_color;
    border: 2px solid @surface2;
    border-radius: 12px;

    /* Icon positioning - GTK CSS */
    background-repeat: no-repeat;
    background-position: center;
    background-size: 64px;

    /* Spacing */
    margin: 10px;

    /* Smooth transitions */
    transition: all 300ms cubic-bezier(0.25, 0.8, 0.25, 1);
  }

  button:focus,
  button:active,
  button:hover {
    background-color: @accent_bg_color;
    color: @accent_fg_color;
    outline-style: none;
    border: 2px solid @accent_color;
    transform: scale(1.08);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
  }

  /* Label styling */
  label {
    font-weight: bold;
    font-size: ${toString (config.stylix.fonts.sizes.applications + 2)}px;
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
