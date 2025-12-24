{ config, lib, pkgs, ... }:

{
  # Hyprlock - Screen lock for Hyprland
  # Style 8 inspired layout with Stylix theme integration
  # Colors, fonts, and wallpaper automatically managed by Stylix

  home-manager.sharedModules = [
    (hm: {
      # Disable Stylix hyprlock target to use custom configuration
      stylix.targets.hyprlock.enable = false;

      programs.hyprlock = {
        enable = true;
        package = pkgs.hyprlock;

        settings = {
          general = {
            hide_cursor = true;
            no_fade_in = false;
            grace = 0;
            disable_loading_bar = false;
          };

          # Background with wallpaper matching Hyprland
          background = [
            {
              monitor = "";
              path = "${hm.config.stylix.image}";

              # Blur settings for nice visual effect
              blur_passes = 2;
              contrast = 0.8916;
              brightness = 0.8172;
              vibrancy = 0.1696;
              vibrancy_darkness = 0.0;
            }
          ];

          # Password input field - Style 8 inspired
          input-field = [
            {
              monitor = "";
              size = "250, 60";
              outline_thickness = 2;

              # Colors from Stylix
              outer_color = "rgba(0, 0, 0, 0)";
              inner_color = "rgba(${hm.config.lib.stylix.colors.base02-rgb-r}, ${hm.config.lib.stylix.colors.base02-rgb-g}, ${hm.config.lib.stylix.colors.base02-rgb-b}, 0.5)";
              font_color = "rgb(${hm.config.lib.stylix.colors.base05-rgb-r}, ${hm.config.lib.stylix.colors.base05-rgb-g}, ${hm.config.lib.stylix.colors.base05-rgb-b})";

              # Dot styling for password characters
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;

              # Failure message with attempt counter
              fade_on_empty = false;
              placeholder_text = "<i><span foreground=\"##${hm.config.lib.stylix.colors.base05}99\">Hi, $USER</span></i>";
              hide_input = false;

              # Position
              position = "0, -290";
              halign = "center";
              valign = "center";
            }
          ];

          # Labels with Style 8 layout
          label = [
            # Hour display - large and prominent
            {
              monitor = "";
              text = "cmd[update:1000] echo -e \"$(date +\"%H\")\"";
              color = "rgba(${hm.config.lib.stylix.colors.base0A-rgb-r}, ${hm.config.lib.stylix.colors.base0A-rgb-g}, ${hm.config.lib.stylix.colors.base0A-rgb-b}, 0.6)";
              font_size = 180;
              font_family = hm.config.stylix.fonts.sansSerif.name;

              position = "0, 300";
              halign = "center";
              valign = "center";
            }

            # Minute display - large and prominent
            {
              monitor = "";
              text = "cmd[update:1000] echo -e \"$(date +\"%M\")\"";
              color = "rgba(${hm.config.lib.stylix.colors.base05-rgb-r}, ${hm.config.lib.stylix.colors.base05-rgb-g}, ${hm.config.lib.stylix.colors.base05-rgb-b}, 0.6)";
              font_size = 180;
              font_family = hm.config.stylix.fonts.sansSerif.name;

              position = "0, 75";
              halign = "center";
              valign = "center";
            }

            # Day and date display
            {
              monitor = "";
              text = "cmd[update:1000] echo \"<span color='##${hm.config.lib.stylix.colors.base05}99'>$(date '+%A, ')</span><span color='##${hm.config.lib.stylix.colors.base0A}99'>$(date '+%d %B')</span>\"";
              font_size = 30;
              font_family = hm.config.stylix.fonts.sansSerif.name;

              position = "0, -80";
              halign = "center";
              valign = "center";
            }

            # Keyboard layout indicator
            {
              monitor = "";
              text = "Current Layout: $LAYOUT";
              color = "rgba(${hm.config.lib.stylix.colors.base05-rgb-r}, ${hm.config.lib.stylix.colors.base05-rgb-g}, ${hm.config.lib.stylix.colors.base05-rgb-b}, 0.7)";
              font_size = 18;
              font_family = hm.config.stylix.fonts.monospace.name;

              position = "0, 60";
              halign = "center";
              valign = "bottom";
            }
          ];
        };
      };
    })
  ];
}
