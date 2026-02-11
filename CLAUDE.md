# Hyprflake

Reusable Hyprland-focused NixOS flake with theming, GPU tuning, and desktop integrations.

## Essentials

- Module library flake — consumed via NixOS or Home Manager modules, not built directly.
- Formatting: `nixpkgs-fmt`. Linting: `statix` + `deadnix`.
- All files must end with exactly one trailing newline.

@extras/docs/commands.md

## Project Map

- `flake.nix` and `lib/` — inputs, module exports, helpers.
- `modules/` — desktop, home, and system modules.
- `modules/options.nix` — all configuration options.
- `docs/` and `extras/docs/` — detailed documentation.

## Gotchas

- This flake publishes module outputs only; it does not build full NixOS systems.
- GPU flags (`nvidia`, `amd`, `intel`) are mutually exclusive in `programs.hyprflake`.
- The consuming flake must include Stylix in its inputs for theming to work.

## Docs (open only when needed)

- `extras/docs/theming.md` — Stylix deep dive, GTK, theme propagation, plymouth
- `docs/styling.md` — styling and theming guidance
- `extras/docs/gpu-configuration.md` — AMD, NVIDIA, Intel setup
- `extras/docs/power-management.md` — idle, sleep, power profiles, TLP, thermal
- `docs/input-management.md` — input devices and keybinding configuration
- `docs/keyring.md` — keyring setup and credential services
- `docs/screensharing.md` — screensharing and portal setup
- `docs/options.md` — configuration option reference
- `extras/docs/consuming-flake.md` — consuming this flake from other projects
- `extras/docs/technical-notes.md` — waybar auto-hide, hyprshell, internals

## Maintenance

See `extras/docs/claude-md/CLAUDE.md` for editing guidance and conventions.
