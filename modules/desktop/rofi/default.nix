{ config, lib, pkgs, ... }:

# Rofi Application Launcher
# Uses adi1090x rofi type-3 style-1 theme with Stylix color integration
# Theme files are local to avoid external dependencies

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };

  # Wrapper for rofi-network-manager to use stylix theme
  # The nixpkgs version calls rofi directly without theme support,
  # so we create a custom rofi wrapper and inject it into PATH
  rofi-themed = pkgs.writeShellScriptBin "rofi" ''
    exec ${lib.getExe pkgs.rofi} -theme "$HOME/.config/ronema/themes/stylix.rasi" "$@"
  '';

  rofi-network-manager-styled = pkgs.symlinkJoin {
    name = "rofi-network-manager-styled";
    paths = [ pkgs.rofi-network-manager ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/rofi-network-manager \
        --prefix PATH : ${rofi-themed}/bin
    '';
  };
in
{
  # Override rofi-network-manager with styled version
  environment.systemPackages = [ rofi-network-manager-styled ];

  # Home Manager Rofi configuration
  home-manager.sharedModules = [
    (_: {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;

        # Terminal to launch from rofi
        terminal = "${lib.getExe pkgs.kitty}";

        # Additional plugins
        plugins = with pkgs; [
          rofi-emoji # Emoji picker
        ];
      };

      # Install adi1090x rofi theme files with Stylix integration
      xdg.configFile = {
        # Type-3 style-1 theme file
        "rofi/launchers/type-3/style-1.rasi" = {
          source = ./type-3/style-1.rasi;
        };

        # Stylix-integrated colors
        "rofi/launchers/type-3/shared/colors.rasi".text = stylix.mkStyle ./type-3/shared/colors.nix;

        # Stylix-integrated fonts
        "rofi/launchers/type-3/shared/fonts.rasi".text = stylix.mkStyle ./type-3/shared/fonts.nix;

        # rofi-network-manager theme
        "ronema/themes/stylix.rasi".text = stylix.mkStyle ./ronema/theme.nix;

        # rofi-network-manager config
        "ronema/ronema.conf".text = ''
          LOCATION=0
          QRCODE_LOCATION=0
          Y_AXIS=0
          X_AXIS=0
          WIDTH_FIX_MAIN=2
          WIDTH_FIX_STATUS=10
          CHANGE_BARS="true"
          SIGNAL_STRENGTH_0=""
          SIGNAL_STRENGTH_1=""
          SIGNAL_STRENGTH_2=""
          SIGNAL_STRENGTH_3=""
          SIGNAL_STRENGTH_4=""
          NOTIFICATIONS="false"
          THEME="stylix"
        '';
      };
    })
  ];
}
