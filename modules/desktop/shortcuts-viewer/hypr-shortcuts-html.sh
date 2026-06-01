#!/usr/bin/env bash
# Render the live Hyprland keybind table to a themed HTML page and open it
# in the default browser. Bind data comes from `hyprctl binds -j` so it is
# always current and includes conf.d binds. Colors/fonts are injected at
# Nix build time (see default.nix) via the @@VAR@@ placeholders.
set -euo pipefail

out="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-shortcuts.html"
mkdir -p "$(dirname "$out")"

# modmask is a numeric bitmask; render the common SUPER (64) / SHIFT (1) /
# CTRL (4) / ALT (8) bits as text, leave anything else as the raw number.
rows="$(hyprctl binds -j | jq -r '
  def mods(m):
    [ if (m % 2) >= 1 then "SHIFT" else empty end,
      if ((m/4) % 2) >= 1 then "CTRL" else empty end,
      if ((m/8) % 2) >= 1 then "ALT" else empty end,
      if ((m/64) % 2) >= 1 then "SUPER" else empty end ] | join(" + ");
  .[]
  | select(.description != "" and .description != null)
  | "<tr><td class=\"k\">" + ((mods(.modmask) | if . == "" then "" else . + " + " end) + .key) + "</td><td>" + .description + "</td></tr>"
')"

cat > "$out" <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>Keybindings</title>
<style>
  body { background: @@BG@@; color: @@FG@@; font-family: "@@FONT@@"; padding: 2rem; }
  h1 { color: @@ACCENT@@; }
  table { border-collapse: collapse; width: 100%; }
  td { padding: .35rem .75rem; border-bottom: 1px solid @@ALT@@; }
  td.k { color: @@ACCENT@@; white-space: nowrap; font-weight: 600; }
</style></head><body>
<h1>Hyprland keybindings</h1>
<table>$rows</table>
</body></html>
HTML

xdg-open "$out"
