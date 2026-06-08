{ config, lib, ... }:

{
  # User profile configuration
  # Sets up AccountsService user photo for the login greeter (DankGreeter)

  options.hyprflake.user = {
    username = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "dustin";
      description = ''
        Username for user-specific configurations.
        Required for features like user profile photo.

        Set this to your primary user's username:
          hyprflake.user.username = "dustin";
      '';
    };

    photo = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./my-photo.jpg";
      description = ''
        Path to user profile photo/avatar image.
        Used by the login greeter (DankGreeter) and AccountsService.

        Requires hyprflake.user.username to be set.
        Photo will be copied to /var/lib/AccountsService/icons/

        Supported formats: JPG, PNG
        Recommended size: 96x96 or larger (square)
      '';
    };
  };

  config = lib.mkIf (config.hyprflake.user.username != null && config.hyprflake.user.photo != null) {
    system.activationScripts.hyprflake-user-photo =
      let
        # username and photo are build-time NixOS options (no runtime attacker
        # path), but they are interpolated into a root activation script, so
        # quote every expansion with escapeShellArg: a name or path with shell
        # metacharacters then lands as a literal filename, never as code run by
        # root at activation. The icon path is the same file the DankGreeter
        # probes per user, so this script feeds the login avatar.
        iconPath = "/var/lib/AccountsService/icons/" + config.hyprflake.user.username;
        userPath = "/var/lib/AccountsService/users/" + config.hyprflake.user.username;
      in
      {
        text = ''
          # Create AccountsService directories
          mkdir -p /var/lib/AccountsService/icons
          mkdir -p /var/lib/AccountsService/users

          # Copy user photo to AccountsService icons directory
          cp ${lib.escapeShellArg (toString config.hyprflake.user.photo)} ${lib.escapeShellArg iconPath}

          # Create AccountsService user configuration. The Icon path is written
          # as a literal line (printf with a quoted format), so the icon path is
          # not re-expanded by the shell.
          printf '[User]\nIcon=%s\n' ${lib.escapeShellArg iconPath} > ${lib.escapeShellArg userPath}
        '';
      };
  };
}
