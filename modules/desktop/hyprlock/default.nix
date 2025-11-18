{ config, lib, pkgs, ... }:

{
  # Hyprlock - Screen lock for Hyprland
  # Minimal configuration with clean design and Stylix theme integration
  # Colors and fonts automatically managed by Stylix

  home-manager.sharedModules = [
    (_: {
      programs.hyprlock = {
        enable = true;
        package = pkgs.hyprlock;

        settings = lib.mkDefault {
          general = {
            hide_cursor = true;
          };

          # Background - colors managed by Stylix
          background = [
            {
              monitor = "";
              # Stylix manages background color

              # Blur settings for nice visual effect
              new_optimizations = true;
              blur_size = 3;
              blur_passes = 2;
              noise = 0.0117;
              contrast = 1.0;
              brightness = 1.0;
              vibrancy = 0.21;
              vibrancy_darkness = 0.0;
            }
          ];

          # Password input field
          input-field = [
            {
              monitor = "";
              size = "250, 50";
              outline_thickness = 3;
              # Outline and background colors managed by Stylix

              # Failure message with attempt counter
              fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
              fail_transition = 300;
              fade_on_empty = false;
              placeholder_text = "Password...";

              # Dot styling for password characters
              dots_size = 0.2;
              dots_spacing = 0.64;
              dots_center = true;

              # Position centered bottom
              position = "0, 140";
              halign = "center";
              valign = "bottom";
            }
          ];

          # Labels - time, greeting, keyboard layout
          label = [
            # Large clock display
            {
              monitor = "";
              text = "$TIME";
              font_size = 64;
              # Font family and color managed by Stylix

              position = "0, 16";
              valign = "center";
              halign = "center";
            }

            # User greeting
            {
              monitor = "";
              text = "Hello <span text_transform=\"capitalize\" size=\"larger\">$USER!</span>";
              font_size = 20;
              # Font family and color managed by Stylix

              position = "0, 100";
              halign = "center";
              valign = "center";
            }

            # Keyboard layout indicator
            {
              monitor = "";
              text = "Current Layout : $LAYOUT";
              font_size = 14;
              # Font family and color managed by Stylix

              position = "0, 20";
              halign = "center";
              valign = "bottom";
            }
          ];
        };
      };
    })
  ];
}
