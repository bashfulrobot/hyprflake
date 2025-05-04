{ config, lib, pkgs, ... }:

{
  # Enable Wayland and XWayland support
  programs.hyprland.enable = true;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  # Install required system packages
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    wayland
    xdg-desktop-portal-hyprland

    # Display and session management
    greetd.tuigreet
    swaylock
    swayidle

    # Notification and UI components
    libnotify
    mako

    # Utilities
    waybar
    wofi
    wl-clipboard
    slurp
    grim

    # Development tools
    git
  ];

  # Configure display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Enable sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Set up XDG portal for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
