{ config, lib, pkgs, ... }:

{
  # Audio configuration for Wayland desktop
  # PipeWire with ALSA and PulseAudio compatibility

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
