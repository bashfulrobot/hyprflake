{ config, lib, pkgs, inputs, ... }:

{
   # Import cachix settings
  imports = [
    ./cachix.nix
    ./xdg.nix
  ];

  # Enable Wayland and XWayland support
  programs.hyprland = {
    enable = true;
    # set the flake package
    package =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # # Enable OpenGL
  # hardware.opengl = {
  #   enable = true;
  #   driSupport = true;
  # };

  # Install required system packages
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    wayland
    xdg-desktop-portal-hyprland
    wl-clipboard

    # Display and session management
    # greetd.tuigreet
    # swaylock
    # swayidle

    # Notification and UI components
    # libnotify
    # mako

    # Utilities
    # waybar
    # wofi
    # wl-clipboard
    # slurp
    grim

    # Development tools
    # git
  ];

  # Configure display manager
  # services.greetd = {
  #   enable = true;
  #   settings = {
  #     default_session = {
  #       command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd Hyprland";
  #       user = "greeter";
  #     };
  #   };
  # };

  # Enable sound
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  # Set up XDG portal for Wayland
  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  # };
}
