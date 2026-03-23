## [0.0.4] - 2025-12-30

### 🚀 Features

- _(release)_ ✨ add git-cliff changelog automation

### 🐛 Bug Fixes

- _(hyprland)_ 🐛 resolve Chrome screen sharing double-prompt
- _(release)_ 🐛 use HEAD instead of non-existent tag in changelog range

### 📚 Documentation

- _(screensharing)_ 📝 document Chrome double-prompt fix

## [0.0.3] - 2025-12-30

### 🚀 Features

- _(cachix)_ ✨ add Hyprland binary cache support
- _(waybar)_ ✨ show only workspaces with open applications
- _(waybar)_ ✨ add comprehensive notification state indicators
- _(hyprland)_ ✨ add Super+Space launcher and Super+T terminal keybindings
- _(waybar)_ ✨ add power button icon to custom power module
- _(waybar)_ ✨ add low battery alert indicator and increase gear icon size
- _(wlogout)_ ✨ add lock and hibernate buttons to menu
- _(hyprland)_ ✨ add Super+B keybind to open default browser
- _(keyring)_ ✨ add auto-discovery for SSH keys
- _(screenshot)_ ✨ replace grimblast/swappy with hyprshot/satty
- _(keybinds)_ ✨ bind Super+P to wlogout power menu
- _(hyprland)_ ✨ add USB automounting support
- _(gnome)_ ✨ enhance Nautilus integration and dconf support
- _(hyprland)_ ✨ add Super+R resize submap with vim/arrow keys
- _(plymouth)_ ✨ add boot splash with Hyprland wallpaper integration
- _(plymouth)_ ✨ switch to Circle HUD theme
- _(plymouth)_ ✨ auto-match theme to colorScheme
- _(network)_ ✨ add rofi-network-manager for WiFi management
- _(waybar)_ ✨ add waybar-auto-hide integration
- _(waybar)_ ✨ expose waybar-auto-hide option through hyprflake
- _(hyprshell)_ Add hyprshell integration with Stylix theming
- _(hyprshell)_ ✨ add window switcher integration
- _(hyprshell)_ ✨ add stylix theme integration
- _(rofi)_ ✨ add adi1090x type-3 style-1 theme
- _(rofi)_ ✨ add border matching hyprland inactive windows
- _(rofi)_ ✨ add stylix theme for rofi-network-manager

### 🐛 Bug Fixes

- _(rofi)_ 🐛 update package from rofi-wayland to rofi
- _(rofi)_ 🐛 update rofi-emoji-wayland to rofi-emoji
- _(cachix)_ 🐛 add .nix extension to cachix import
- _(keyring)_ 🔒 add SSH_ASKPASS and polkit agent for passphrase storage
- _(keyring)_ 🐛 use lib.mkForce for SSH_ASKPASS to override NixOS default
- _(keyring)_ 🐛 change SSH/secrets services to oneshot type
- _(keyring)_ 🔒 bahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
- _(hyprland)_ 🐛 remove blueman-applet autostart to prevent duplicate icons
- _(waybar)_ 🐛 revert gear icon to standard character for compatibility
- _(waybar)_ 🐛 use visible bell icons for notification status
- _(wlogout)_ 🐛 correct button sizing using GTK CSS and layout props
- _(waybar)_ 🐛 add spacing and margin params to wlogout launch
- _(waybar)_ 🐛 add buttons-per-row parameter to wlogout command
- _(wlogout)_ 🐛 use correct icon paths to prevent red error stripes
- _(waybar)_ 🐛 change wlogout to 2 buttons per row for square layout
- _(waybar)_ 🐛 update wlogout to use 3-button-per-row layout
- _(waybar)_ 🐛 improve workspace number centering
- _(waybar)_ 🐛 remove invalid line-height property from workspace CSS
- _(waybar)_ 🐛 increase disconnected WiFi icon size to prevent cutoff
- _(keyring)_ 🐛 enable systemd service to prevent session logout kill
- _(keyring)_ 🐛 add missing environment variables for auto-unlock
- _(keyring)_ 🐛 remove SSH_ASKPASS_REQUIRE to fix terminal SSH
- _(hyprland)_ 🐛 remove duplicate SSH_ASKPASS_REQUIRE setting
- Move Nautilus configuration to imported hyprland module
- _(plymouth)_ 🐛 force bgrt theme to avoid conflicts
- _(plymouth)_ 🐛 force theme to avoid Stylix conflict
- _(waybar)_ 🐛 add startup delay for waybar-auto-hide
- _(waybar)_ 🐛 add psmisc dependency for waybar-auto-hide
- _(waybar)_ 🐛 add signal handlers for waybar-auto-hide
- _(waybar)_ 🐛 update waybar-auto-hide with NixOS wrapper fix
- _(waybar)_ Update waybar-auto-hide with corrected patch syntax
- _(keyring)_ 🐛 resolve intermittent auto-unlock failures
- _(hyprshell)_ Correct settings path for max_items
- _(hyprshell)_ Switch to hyprshell branch for Hyprland 0.52 compatibility
- _(hyprshell)_ Remove invalid 'enable' fields from config
- _(hyprshell)_ 🐛 correct module attribute path
- _(hyprshell)_ 🐛 remove invalid launcher configuration
- _(hyprshell)_ 🐛 use CSS custom properties for GTK styling
- _(rofi)_ 🐛 reduce transparency for better readability
- _(rofi)_ 🐛 remove all transparency for solid background
- _(waybar)_ 🐛 apply stylix theme to rofi-network-manager
- Rofi network manager style
- _(keyring)_ 🐛 use official gnome-keyring service to prevent duplicate daemon
- _(keyring)_ 🐛 replace /dev/null symlink with stub D-Bus service
- _(keyring)_ 🐛 enable automatic unlock on hyprlock authentication
- _(hyprshell)_ 🐛 correct config schema for nixpkgs version
- _(hyprland)_ 🐛 add missing portal and priority config

### 💼 Other

- _(lockfile)_ Update flake lock for updates.
- _(hyprland)_ ⬆️ replace pavucontrol with pwvucontrol for native PipeWire support

### 🚜 Refactor

- _(waybar)_ ♻️ simplify workspace button CSS for better centering
- _(waybar)_ ♻️ simplify workspace format to icon-only display
- _(waybar)_ ♻️ simplify inactive notification icon to dot
- _(wlogout)_ ♻️ simplify layout using percentage-based sizing
- _(hyprshell)_ Switch from flake input to nixpkgs package
- Remove hyprshell integration completely
- _(options)_ ♻️ reorganize into nested hierarchy with style/desktop/system/user
- _(deps)_ [**breaking**] ♻️ migrate from Hyprland flake to nixpkgs
- _(modules)_ ♻️ consolidate attribute sets per Nix best practices

### 📚 Documentation

- 📝 document input follows pattern and cachix
- _(keyring)_ 📝 add comprehensive keyring, SSH, and GPG integration guide
- _(keyring)_ 📝 consolidate and minimize documentation
- _(readme)_ 📝 add Hyprland version control pattern
- _(plymouth)_ 📝 update for auto-theme matching
- _(hyprflake)_ Update hyprshell to correct branch and strengthen follows docs
- Update README and default.nix for improved clarity on Stylix integration
- _(keyring)_ 📝 remove obsolete documentation files
- _(keyring)_ 📝 comprehensive rewrite with tiling WM focus
- _(flake)_ 📝 add comprehensive input management guide with dependency diagram
- _(input-management)_ 📝 update for nixpkgs architecture

### 🎨 Styling

- _(waybar)_ 💄 fix workspace number vertical centering
- _(waybar)_ 💄 use balanced padding for GTK CSS text centering
- _(waybar)_ 💄 remove all padding from workspace buttons
- _(waybar)_ 💄 improve system gear icon visibility
- _(waybar)_ 💄 standardize all icon sizes to 20px
- _(waybar)_ 💄 fine-tune icon sizes for visual hierarchy
- _(waybar)_ 💄 increase tooltip and calendar size for readability
- _(waybar)_ 💄 reduce inactive notification dot size for subtlety
- _(waybar)_ 💄 further reduce notification dot to 6pt for minimalism
- _(waybar)_ 💄 reduce power icon size from 20px to 18px
- _(waybar)_ 🎨 unify clock and power button colors to blue theme
- _(wlogout)_ 💄 redesign menu with compact square buttons and Stylix integration
- _(wlogout)_ 💄 add explicit label styling for text visibility
- _(wlogout)_ 💄 add square button sizing constraints
- _(wlogout)_ 💄 add padding to increase button height
- _(wlogout)_ 💄 remove padding/margin and restore rounded corners
- _(waybar)_ 💄 add spacing between wlogout buttons
- _(waybar)_ 💄 increase wlogout button spacing to 60px
- _(waybar)_ 💄 make workspace indicators square
- Update hyprlock configuration for improved aesthetics and functionality

### ⚙️ Miscellaneous Tasks

- 🔧 add gitignore for nix build artifacts
- 🔧 update flake dependencies
- Remove unused hyprland.nix file
- 🔧 add flake.lock for reproducible builds
- Update flake inputs (home-manager, hyprland, nixpkgs)
- Update flake inputs (waybar-auto-hide)
- _(hyprland)_ 🔧 reverse trackpad natural scroll setting
- _(docs)_ 🧹 clean up project root and reorganize documentation

### ◀️ Revert

- _(waybar)_ ⏪ use default zero vertical padding for workspace buttons
