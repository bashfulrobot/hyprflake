# Commands

Use `just` for most maintenance tasks:

- `just fmt` - format Nix files
- `just lint` - run statix
- `just fix` - auto-fix statix findings
- `just health` - deadnix + statix
- `just check` - `nix flake check`
- `just eval` - verify module export evaluates
- `just bump [input]` - move tag/SHA-pinned input(s) to the latest release/commit; all pinned inputs if no arg
- `just bump-hyprflake` - bump + update every input, `nix flake check`, then commit + push to main
- `just update` - `nix flake update`: advance branch-tracking inputs (pinned tags/SHAs stay put)
- `just update-input <input>` - update one input's lock
- `just show` - show flake outputs
- `just info` - show flake metadata

Release helpers (library publishing):

- `just changelog` - update CHANGELOG.md (unreleased)
- `just changelog-full` - regenerate full changelog
- `just release type=patch|minor|major` - release workflow
- `just publish` - build outputs and push to cachix
