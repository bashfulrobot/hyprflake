## [0.0.3] - 2025-12-30

### 🚀 Features

- *(cachix)* ✨ add Hyprland binary cache support
- *(waybar)* ✨ show only workspaces with open applications
- *(waybar)* ✨ add comprehensive notification state indicators
- *(hyprland)* ✨ add Super+Space launcher and Super+T terminal keybindings
- *(waybar)* ✨ add power button icon to custom power module
- *(waybar)* ✨ add low battery alert indicator and increase gear icon size
- *(wlogout)* ✨ add lock and hibernate buttons to menu
- *(hyprland)* ✨ add Super+B keybind to open default browser
- *(keyring)* ✨ add auto-discovery for SSH keys
- *(screenshot)* ✨ replace grimblast/swappy with hyprshot/satty
- *(keybinds)* ✨ bind Super+P to wlogout power menu
- *(hyprland)* ✨ add USB automounting support
- *(gnome)* ✨ enhance Nautilus integration and dconf support
- *(hyprland)* ✨ add Super+R resize submap with vim/arrow keys
- *(plymouth)* ✨ add boot splash with Hyprland wallpaper integration
- *(plymouth)* ✨ switch to Circle HUD theme
- *(plymouth)* ✨ auto-match theme to colorScheme
- *(network)* ✨ add rofi-network-manager for WiFi management
- *(waybar)* ✨ add waybar-auto-hide integration
- *(waybar)* ✨ expose waybar-auto-hide option through hyprflake
- *(hyprshell)* Add hyprshell integration with Stylix theming
- *(hyprshell)* ✨ add window switcher integration
- *(hyprshell)* ✨ add stylix theme integration
- *(rofi)* ✨ add adi1090x type-3 style-1 theme
- *(rofi)* ✨ add border matching hyprland inactive windows
- *(rofi)* ✨ add stylix theme for rofi-network-manager

### 🐛 Bug Fixes

- *(rofi)* 🐛 update package from rofi-wayland to rofi
- *(rofi)* 🐛 update rofi-emoji-wayland to rofi-emoji
- *(cachix)* 🐛 add .nix extension to cachix import
- *(keyring)* 🔒 add SSH_ASKPASS and polkit agent for passphrase storage
- *(keyring)* 🐛 use lib.mkForce for SSH_ASKPASS to override NixOS default
- *(keyring)* 🐛 change SSH/secrets services to oneshot type
- *(keyring)* 🔒 bahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
- *(hyprland)* 🐛 remove blueman-applet autostart to prevent duplicate icons
- *(waybar)* 🐛 revert gear icon to standard character for compatibility
- *(waybar)* 🐛 use visible bell icons for notification status
- *(wlogout)* 🐛 correct button sizing using GTK CSS and layout props
- *(waybar)* 🐛 add spacing and margin params to wlogout launch
- *(waybar)* 🐛 add buttons-per-row parameter to wlogout command
- *(wlogout)* 🐛 use correct icon paths to prevent red error stripes
- *(waybar)* 🐛 change wlogout to 2 buttons per row for square layout
- *(waybar)* 🐛 update wlogout to use 3-button-per-row layout
- *(waybar)* 🐛 improve workspace number centering
- *(waybar)* 🐛 remove invalid line-height property from workspace CSS
- *(waybar)* 🐛 increase disconnected WiFi icon size to prevent cutoff
- *(keyring)* 🐛 enable systemd service to prevent session logout kill
- *(keyring)* 🐛 add missing environment variables for auto-unlock
- *(keyring)* 🐛 remove SSH_ASKPASS_REQUIRE to fix terminal SSH
- *(hyprland)* 🐛 remove duplicate SSH_ASKPASS_REQUIRE setting
- Move Nautilus configuration to imported hyprland module
- *(plymouth)* 🐛 force bgrt theme to avoid conflicts
- *(plymouth)* 🐛 force theme to avoid Stylix conflict
- *(waybar)* 🐛 add startup delay for waybar-auto-hide
- *(waybar)* 🐛 add psmisc dependency for waybar-auto-hide
- *(waybar)* 🐛 add signal handlers for waybar-auto-hide
- *(waybar)* 🐛 update waybar-auto-hide with NixOS wrapper fix
- *(waybar)* Update waybar-auto-hide with corrected patch syntax
- *(keyring)* 🐛 resolve intermittent auto-unlock failures
- *(hyprshell)* Correct settings path for max_items
- *(hyprshell)* Switch to hyprshell branch for Hyprland 0.52 compatibility
- *(hyprshell)* Remove invalid 'enable' fields from config
- *(hyprshell)* 🐛 correct module attribute path
- *(hyprshell)* 🐛 remove invalid launcher configuration
- *(hyprshell)* 🐛 use CSS custom properties for GTK styling
- *(rofi)* 🐛 reduce transparency for better readability
- *(rofi)* 🐛 remove all transparency for solid background
- *(waybar)* 🐛 apply stylix theme to rofi-network-manager
- Rofi network manager style
- *(keyring)* 🐛 use official gnome-keyring service to prevent duplicate daemon
- *(keyring)* 🐛 replace /dev/null symlink with stub D-Bus service
- *(keyring)* 🐛 enable automatic unlock on hyprlock authentication
- *(hyprshell)* 🐛 correct config schema for nixpkgs version
- *(hyprland)* 🐛 add missing portal and priority config

### 💼 Other

- *(lockfile)* Update flake lock for updates.
- *(hyprland)* ⬆️ replace pavucontrol with pwvucontrol for native PipeWire support

### 🚜 Refactor

- *(waybar)* ♻️ simplify workspace button CSS for better centering
- *(waybar)* ♻️ simplify workspace format to icon-only display
- *(waybar)* ♻️ simplify inactive notification icon to dot
- *(wlogout)* ♻️ simplify layout using percentage-based sizing
- *(hyprshell)* Switch from flake input to nixpkgs package
- Remove hyprshell integration completely
- *(options)* ♻️ reorganize into nested hierarchy with style/desktop/system/user
- *(deps)* [**breaking**] ♻️ migrate from Hyprland flake to nixpkgs
- *(modules)* ♻️ consolidate attribute sets per Nix best practices

### 📚 Documentation

- 📝 document input follows pattern and cachix
- *(keyring)* 📝 add comprehensive keyring, SSH, and GPG integration guide
- *(keyring)* 📝 consolidate and minimize documentation
- *(readme)* 📝 add Hyprland version control pattern
- *(plymouth)* 📝 update for auto-theme matching
- *(hyprflake)* Update hyprshell to correct branch and strengthen follows docs
- Update README and default.nix for improved clarity on Stylix integration
- *(keyring)* 📝 remove obsolete documentation files
- *(keyring)* 📝 comprehensive rewrite with tiling WM focus
- *(flake)* 📝 add comprehensive input management guide with dependency diagram
- *(input-management)* 📝 update for nixpkgs architecture

### 🎨 Styling

- *(waybar)* 💄 fix workspace number vertical centering
- *(waybar)* 💄 use balanced padding for GTK CSS text centering
- *(waybar)* 💄 remove all padding from workspace buttons
- *(waybar)* 💄 improve system gear icon visibility
- *(waybar)* 💄 standardize all icon sizes to 20px
- *(waybar)* 💄 fine-tune icon sizes for visual hierarchy
- *(waybar)* 💄 increase tooltip and calendar size for readability
- *(waybar)* 💄 reduce inactive notification dot size for subtlety
- *(waybar)* 💄 further reduce notification dot to 6pt for minimalism
- *(waybar)* 💄 reduce power icon size from 20px to 18px
- *(waybar)* 🎨 unify clock and power button colors to blue theme
- *(wlogout)* 💄 redesign menu with compact square buttons and Stylix integration
- *(wlogout)* 💄 add explicit label styling for text visibility
- *(wlogout)* 💄 add square button sizing constraints
- *(wlogout)* 💄 add padding to increase button height
- *(wlogout)* 💄 remove padding/margin and restore rounded corners
- *(waybar)* 💄 add spacing between wlogout buttons
- *(waybar)* 💄 increase wlogout button spacing to 60px
- *(waybar)* 💄 make workspace indicators square
- Update hyprlock configuration for improved aesthetics and functionality

### ⚙️ Miscellaneous Tasks

- 🔧 add gitignore for nix build artifacts
- 🔧 update flake dependencies
- Remove unused hyprland.nix file
- 🔧 add flake.lock for reproducible builds
- Update flake inputs (home-manager, hyprland, nixpkgs)
- Update flake inputs (waybar-auto-hide)
- *(hyprland)* 🔧 reverse trackpad natural scroll setting
- *(docs)* 🧹 clean up project root and reorganize documentation

### ◀️ Revert

- *(waybar)* ⏪ use default zero vertical padding for workspace buttons
