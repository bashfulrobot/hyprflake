{ config }: ''
  /**
   * Fonts - Stylix Integration
   * Based on adi1090x rofi themes
   **/

  * {
      font: "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.applications}";
  }
''
