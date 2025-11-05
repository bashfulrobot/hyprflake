{ config, lib, pkgs, ... }:

{
  # Graphics configuration for Wayland
  # Enables OpenGL and Vulkan with 32-bit support for games/Steam

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
