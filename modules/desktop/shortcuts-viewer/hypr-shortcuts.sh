#!/usr/bin/env bash
# hypr-shortcuts - Display Hyprland keybindings and global shortcuts
# Usage: hypr-shortcuts [binds|global] [rofi|terminal]

set -euo pipefail

# Format keybindings into human-readable format
format_bindings() {
  hyprctl binds -j | jq -r '
    # Define a function to convert modmask to a string
    def modmask_to_string:
      [
        if . & 64 == 64 then "SUPER" else empty end, # SUPER (Mod4)
        if . & 1 == 1 then "SHIFT" else empty end,   # SHIFT
        if . & 4 == 4 then "CTRL" else empty end,    # CTRL
        if . & 8 == 8 then "ALT" else empty end      # ALT
      ] | join(",");

    .[] |
    [
      (.modmask | modmask_to_string |
        gsub("SUPER"; "󰘳 Super") |
        gsub("SHIFT"; "󰘶 Shift") |
        gsub("CTRL"; " Ctrl") |
        gsub("ALT"; "󰘵 Alt") |
        gsub(","; " + ")),
      .key,
      "→",
      .dispatcher,
      (.arg // "")
    ] | @tsv' | column -t -s $'\t'
}

# Format global shortcuts into human-readable format
format_global() {
  hyprctl globalshortcuts -j | jq -r '.[] |
    [
      .name,
      "→",
      (.description // "No description")
    ] | @tsv' | column -t -s $'\t'
}

# Show in rofi
show_rofi() {
  local prompt="$1"
  local content="$2"

  echo "$content" | rofi -dmenu -i \
    -p "$prompt" \
    -theme-str 'window {width: 70%; height: 60%;}' \
    -theme-str 'listview {lines: 20;}' \
    -theme-str 'element-text {font: "monospace 10";}'
}

# Show in terminal with fzf
show_terminal() {
  local prompt="$1"
  local header="$2"
  local content="$3"

  echo "$content" | fzf \
    --prompt="$prompt > " \
    --header="$header" \
    --preview-window=hidden \
    --height=80% \
    --layout=reverse \
    --border \
    --info=inline
}

# Main logic
TYPE="${1:-binds}"
DISPLAY="${2:-rofi}"

case "$TYPE" in
  binds)
    CONTENT=$(format_bindings)
    PROMPT="Hyprland Keybindings"
    HEADER="MODIFIERS | KEY | → | ACTION | ARGUMENT"
    ;;
  global)
    CONTENT=$(format_global)
    PROMPT="Global Shortcuts"
    HEADER="NAME | → | DESCRIPTION"
    ;;
  *)
    echo "Usage: $0 [binds|global] [rofi|terminal]"
    exit 1
    ;;
esac

case "$DISPLAY" in
  rofi)
    show_rofi "$PROMPT" "$CONTENT"
    ;;
  terminal)
    # Check if running in terminal
    if [ -t 1 ]; then
      show_terminal "$PROMPT" "$HEADER" "$CONTENT"
    else
      # Not in terminal, try to launch in one
      if command -v kitty &> /dev/null; then
        kitty --class="floating" -e bash -c "echo '$CONTENT' | fzf --prompt='$PROMPT > ' --header='$HEADER' --preview-window=hidden --height=80% --layout=reverse --border --info=inline; read -p 'Press Enter to close...'"
      elif command -v foot &> /dev/null; then
        foot -a floating -e bash -c "echo '$CONTENT' | fzf --prompt='$PROMPT > ' --header='$HEADER' --preview-window=hidden --height=80% --layout=reverse --border --info=inline; read -p 'Press Enter to close...'"
      else
        # Fallback to rofi if no terminal available
        show_rofi "$PROMPT" "$CONTENT"
      fi
    fi
    ;;
  *)
    echo "Display must be 'rofi' or 'terminal'"
    exit 1
    ;;
esac
