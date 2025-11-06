{ config, lib, pkgs, ... }:

{
  # XDG Base Directory specification support
  # Ensures proper application data directories

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  # XDG user directories via Home Manager
  home-manager.sharedModules = [
    (_: {
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };
    })
  ];
}
