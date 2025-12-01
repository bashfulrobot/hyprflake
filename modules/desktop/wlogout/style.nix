{ config }: ''
  /* Wlogout styling with Stylix base16 color integration */

  * {
    background-image: none;
    box-shadow: none;
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  window {
    background-color: rgba(0, 0, 0, 0.5);
  }

  button {
    background-color: @theme_base_color;
    color: @theme_text_color;
    border: 2px solid @accent_color;
    border-radius: 8px;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
    margin: 10px;
    transition: all 0.2s ease-in-out;
  }

  button:focus,
  button:active,
  button:hover {
    background-color: @accent_bg_color;
    color: @accent_fg_color;
    outline-style: none;
    border: 2px solid @accent_color;
    transform: scale(1.05);
  }

  #logout {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
  }

  #suspend {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
  }

  #shutdown {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
  }

  #reboot {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
  }
''
