{ config, lib, pkgs, ... }:

with lib;

{
  options.programs.hyprflake = {
    enable = mkEnableOption "Enable Hyprland desktop environment";

    nvidia = mkEnableOption "Enable NVIDIA GPU optimizations";
    amd = mkEnableOption "Enable AMD GPU optimizations";
    intel = mkEnableOption "Enable Intel GPU optimizations";

    theme = {
      gtkTheme = mkOption {
        type = types.str;
        default = "Adwaita-dark";
        description = "GTK theme name";
      };

      iconTheme = mkOption {
        type = types.str;
        default = "Adwaita";
        description = "Icon theme name";
      };

      cursorTheme = mkOption {
        type = types.str;
        default = "Adwaita";
        description = "Cursor theme name";
      };

      cursorSize = mkOption {
        type = types.int;
        default = 24;
        description = "Cursor size";
      };
    };
  };

  config = mkIf config.programs.hyprflake.enable {
    # Enable Hyprland
    programs.hyprland.enable = true;

    # XDG Desktop Portal
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };

    # Security and authentication
    security.polkit.enable = true;

    # Graphics drivers
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # AMD GPU specific configuration
    hardware.amdgpu = mkIf config.programs.hyprflake.amd {
      initrd = true;
    };

    # NVIDIA GPU specific configuration
    hardware.nvidia = mkIf config.programs.hyprflake.nvidia {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Intel GPU specific configuration
    hardware.intel-gpu-tools = mkIf config.programs.hyprflake.intel {
      enable = true;
    };

    # Fonts
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
    ];

    # Environment variables for Wayland
    environment.sessionVariables = mkMerge [
      {
        NIXOS_OZONE_WL = "1";
      }
      # NVIDIA-specific environment variables
      (mkIf config.programs.hyprflake.nvidia {
        LIBVA_DRIVER_NAME = "nvidia";
        XDG_SESSION_TYPE = "wayland";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";
      })
    ];

    # Audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}