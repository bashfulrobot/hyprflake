{ config }: ''
  /* Hyprshell Styling - Stylix Base16 Theme Integration */
  /* Matches Catppuccin and other base16 color schemes */
  /* Uses GTK4 CSS subset - see https://docs.gtk.org/gtk4/css-overview.html */

  /* Global CSS Variables */
  :root {
    /* Base16 color palette from Stylix */
    --base00: #${config.lib.stylix.colors.base00}; /* Background */
    --base01: #${config.lib.stylix.colors.base01}; /* Surface 0 */
    --base02: #${config.lib.stylix.colors.base02}; /* Surface 1 */
    --base03: #${config.lib.stylix.colors.base03}; /* Surface 2 / Overlay */
    --base04: #${config.lib.stylix.colors.base04}; /* Subtext */
    --base05: #${config.lib.stylix.colors.base05}; /* Text / Foreground */
    --base06: #${config.lib.stylix.colors.base06}; /* Light text */
    --base07: #${config.lib.stylix.colors.base07}; /* Lightest text */
    --base08: #${config.lib.stylix.colors.base08}; /* Red / Error */
    --base09: #${config.lib.stylix.colors.base09}; /* Orange */
    --base0A: #${config.lib.stylix.colors.base0A}; /* Yellow / Warning */
    --base0B: #${config.lib.stylix.colors.base0B}; /* Green / Success */
    --base0C: #${config.lib.stylix.colors.base0C}; /* Cyan / Teal */
    --base0D: #${config.lib.stylix.colors.base0D}; /* Blue / Accent */
    --base0E: #${config.lib.stylix.colors.base0E}; /* Purple / Magenta */
    --base0F: #${config.lib.stylix.colors.base0F}; /* Pink / Flamingo */

    /* Semantic color aliases for Catppuccin compatibility */
    --accent: var(--base0D);
    --accent-hover: var(--base0C);
    --text-primary: var(--base05);
    --text-secondary: var(--base04);
    --background: var(--base00);
    --surface: var(--base01);
    --surface-bright: var(--base02);
    --border: var(--base03);
    --error: var(--base08);
    --warning: var(--base0A);
    --success: var(--base0B);
  }

  /* Global defaults */
  * {
    font-family: "${config.stylix.fonts.sansSerif.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
    color: var(--text-primary);
  }

  /* Main window background */
  window {
    background-color: alpha(var(--background), ${toString config.stylix.opacity.popups});
    color: var(--text-primary);
    border-radius: 12px;
  }

  /* Overview/Window Switcher Container */
  .overview {
    background-color: alpha(var(--background), 0.95);
    padding: 20px;
  }

  /* Window preview tiles */
  .window-preview {
    background-color: var(--surface);
    border: 2px solid var(--border);
    border-radius: 8px;
    padding: 8px;
    margin: 6px;
    transition: all 200ms ease;
  }

  .window-preview:hover {
    background-color: var(--surface-bright);
    border-color: var(--accent);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  }

  .window-preview:selected,
  .window-preview:active {
    background-color: var(--accent);
    border-color: var(--accent);
    color: var(--background);
  }

  /* Window titles in overview */
  .window-title {
    font-weight: 500;
    color: var(--text-primary);
    padding: 4px 8px;
  }

  .window-preview:selected .window-title,
  .window-preview:active .window-title {
    color: var(--background);
    font-weight: bold;
  }

  /* Application Launcher */
  .launcher {
    background-color: alpha(var(--background), ${toString config.stylix.opacity.popups});
    border: 2px solid var(--accent);
    border-radius: 12px;
    padding: 16px;
  }

  /* Search input field */
  entry,
  .search-entry {
    background-color: var(--surface);
    color: var(--text-primary);
    border: 2px solid var(--border);
    border-radius: 8px;
    padding: 12px 16px;
    font-size: ${toString (config.stylix.fonts.sizes.applications + 2)}px;
    caret-color: var(--accent);
  }

  entry:focus,
  .search-entry:focus {
    border-color: var(--accent);
    box-shadow: 0 0 0 1px var(--accent);
  }

  entry::placeholder,
  .search-entry::placeholder {
    color: var(--text-secondary);
  }

  /* Launcher item list */
  .launcher-list,
  list {
    background-color: transparent;
    padding: 8px 0;
  }

  /* Individual launcher items */
  .launcher-item,
  listitem,
  row {
    background-color: transparent;
    border-radius: 6px;
    padding: 10px 12px;
    margin: 2px 0;
    transition: all 150ms ease;
  }

  .launcher-item:hover,
  listitem:hover,
  row:hover {
    background-color: var(--surface);
  }

  .launcher-item:selected,
  .launcher-item:active,
  listitem:selected,
  row:selected {
    background-color: var(--accent);
    color: var(--background);
  }

  /* App icons in launcher */
  .app-icon,
  image {
    margin-right: 12px;
  }

  /* App names and descriptions */
  .app-name {
    font-weight: 500;
    color: var(--text-primary);
    font-size: ${toString (config.stylix.fonts.sizes.applications + 1)}px;
  }

  .launcher-item:selected .app-name,
  listitem:selected .app-name,
  row:selected .app-name {
    color: var(--background);
    font-weight: bold;
  }

  .app-description {
    color: var(--text-secondary);
    font-size: ${toString (config.stylix.fonts.sizes.applications - 1)}px;
  }

  .launcher-item:selected .app-description,
  listitem:selected .app-description,
  row:selected .app-description {
    color: alpha(var(--background), 0.8);
  }

  /* Scrollbar styling */
  scrollbar {
    background-color: transparent;
    border: none;
  }

  scrollbar trough {
    background-color: transparent;
  }

  scrollbar slider {
    background-color: var(--surface);
    border-radius: 8px;
    min-width: 6px;
    min-height: 40px;
    border: 1px solid var(--border);
  }

  scrollbar slider:hover {
    background-color: var(--surface-bright);
  }

  scrollbar slider:active {
    background-color: var(--accent);
  }

  /* Buttons (if any) */
  button {
    background-color: var(--surface);
    color: var(--text-primary);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 8px 16px;
    font-weight: 500;
    transition: all 150ms ease;
  }

  button:hover {
    background-color: var(--surface-bright);
    border-color: var(--accent);
  }

  button:active {
    background-color: var(--accent);
    color: var(--background);
  }

  button:disabled {
    opacity: 0.5;
  }

  /* Labels */
  label {
    color: var(--text-primary);
  }

  /* Workspace indicators (if shown) */
  .workspace-indicator {
    background-color: var(--surface);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 4px 8px;
    margin: 2px;
  }

  .workspace-indicator.active {
    background-color: var(--accent);
    color: var(--background);
    border-color: var(--accent);
  }

  /* Plugin sections (calculator, web search, etc.) */
  .plugin-result {
    background-color: var(--surface);
    border: 1px solid var(--accent);
    border-left-width: 3px;
    border-radius: 6px;
    padding: 10px 12px;
    margin: 4px 0;
  }

  .plugin-title {
    font-weight: bold;
    color: var(--accent);
    font-size: ${toString (config.stylix.fonts.sizes.applications + 1)}px;
  }

  .plugin-description {
    color: var(--text-secondary);
    font-size: ${toString (config.stylix.fonts.sizes.applications - 1)}px;
  }

  /* Separators */
  separator {
    background-color: var(--border);
    min-height: 1px;
    min-width: 1px;
    margin: 8px 0;
  }

  /* Box containers */
  box {
    background-color: transparent;
  }

  /* Tooltips */
  tooltip {
    background-color: var(--surface);
    color: var(--text-primary);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 6px 10px;
    font-size: ${toString (config.stylix.fonts.sizes.applications - 1)}px;
  }

  /* Overlay/backdrop */
  .overlay {
    background-color: alpha(var(--background), 0.8);
  }
''
