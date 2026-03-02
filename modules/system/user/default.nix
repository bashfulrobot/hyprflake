{ config, lib, ... }:

{
  # User profile configuration
  # Sets up AccountsService user photo for display managers (GDM, etc.)

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
        Used by display managers (GDM) and AccountsService.

        Requires hyprflake.user.username to be set.
        Photo will be copied to /var/lib/AccountsService/icons/

        Supported formats: JPG, PNG
        Recommended size: 96x96 or larger (square)
      '';
    };
  };

  config = lib.mkIf (config.hyprflake.user.username != null && config.hyprflake.user.photo != null) {
    system.activationScripts.hyprflake-user-photo = {
      text = ''
                # Create AccountsService directories
                mkdir -p /var/lib/AccountsService/icons
                mkdir -p /var/lib/AccountsService/users

                # Copy user photo to AccountsService icons directory
                cp ${config.hyprflake.user.photo} /var/lib/AccountsService/icons/${config.hyprflake.user.username}

                # Create AccountsService user configuration
                cat > /var/lib/AccountsService/users/${config.hyprflake.user.username} << 'EOF'
        [User]
        Icon=/var/lib/AccountsService/icons/${config.hyprflake.user.username}
        EOF
      '';
    };
  };
}
