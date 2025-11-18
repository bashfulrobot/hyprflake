{ config, lib, pkgs, ... }:

{
  # User profile photo configuration
  # Sets up AccountsService user photo for display managers (GDM, etc.)

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
