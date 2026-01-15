{ ... }:

{
  # Power Management Module Aggregator
  # Imports all power management related modules

  imports = [
    ./profiles-daemon.nix
    ./tlp.nix
    ./thermal.nix
    ./sleep.nix
    ./logind.nix
  ];
}
