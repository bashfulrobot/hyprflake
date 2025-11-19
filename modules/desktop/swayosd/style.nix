{ config }: ''
  /* SwayOSD Styling - Stylix Base16 Theme */

  window {
    border-radius: 8px;
    opacity: ${toString config.stylix.opacity.popups};
    border: 2px solid #${config.lib.stylix.colors.base0D};
    background-color: #${config.lib.stylix.colors.base00};
    padding: 12px;
  }

  label {
    font-family: "${config.stylix.fonts.monospace.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}pt;
    color: #${config.lib.stylix.colors.base05};
    font-weight: bold;
  }

  image {
    color: #${config.lib.stylix.colors.base0D};
  }

  progressbar {
    border-radius: 4px;
    background-color: #${config.lib.stylix.colors.base01};
    border: 1px solid #${config.lib.stylix.colors.base03};
  }

  progress {
    background-color: #${config.lib.stylix.colors.base0D};
    border-radius: 4px;
  }
''
