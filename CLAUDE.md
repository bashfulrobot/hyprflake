# Hyprflake

## Rules

- Module library flake; consumed via NixOS or Home Manager modules.
- Use `nixpkgs-fmt`, `statix`, and `deadnix`.
- Files always end with a blank line.
- **DMS-first.** DankMaterialShell is the core shell. For any desktop-shell
  feature, prefer DMS's built-in capability over adding a standalone tool; only
  reach for a separate tool when DMS genuinely lacks it, and document the
  exception. See `docs/architecture.md` ("DMS-first principle").

## Docs (open only when needed)

- `docs/architecture.md` — module structure, consumer wiring, public surface.
- `docs/commands.md` — `just` recipes and common commands.
- `docs/options.md` — options reference.
- `docs/styling.md` — Stylix integration and theming.
- `docs/power-management.md` — TLP / PPD / sleep / lid / battery options.
- `docs/window-rules.md` — Hyprland window rules syntax (0.53+).
- `docs/keyring.md`, `docs/screensharing.md`, `docs/input-management.md`, `docs/voxtype.md`, `docs/technical-notes.md` — topic deep-dives.
- `docs/workarounds.md` — active upstream-bug patches in hyprflake; revisit on every nixpkgs bump that touches gdm / gnome-session / hyprpolkitagent.
