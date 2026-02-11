# Commands

Use `just` for most maintenance tasks:

- `just fmt` - format Nix files
- `just lint` - run statix
- `just fix` - auto-fix statix findings
- `just health` - deadnix + statix
- `just check` - `nix flake check`
- `just eval` - verify module export evaluates
- `just update` - update all flake inputs
- `just update-input <input>` - update one input
- `just show` - show flake outputs
- `just info` - show flake metadata

Release helpers (library publishing):

- `just changelog` - update CHANGELOG.md (unreleased)
- `just changelog-full` - regenerate full changelog
- `just release type=patch|minor|major` - release workflow
- `just publish` - build outputs and push to cachix
