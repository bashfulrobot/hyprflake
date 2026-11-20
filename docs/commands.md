# Commands

Use `just` for most maintenance tasks:

- `just fmt` - format Nix files
- `just lint` - run statix
- `just fix` - auto-fix statix findings
- `just health` - deadnix + statix
- `just check` - `nix flake check`: evaluates the full module set with home-manager, runs statix, deadnix, shellcheck, the script tests, builds the `hypr-*` helpers, and runs Hyprland's config verifier over the generated `hyprland.lua`
- `just eval` - verify module export evaluates
- `just bump [input]` - move tag/SHA-pinned input(s) to the latest release/commit; all pinned inputs if no arg
- `just bump-hyprflake` - bump + update every input, `nix flake check`, then commit + push to main
- `just update` - `nix flake update`: advance branch-tracking inputs (pinned tags/SHAs stay put)
- `just update-input <input>` - update one input's lock
- `just update-lock` - `nix flake update` + `nix flake check`, then commit `flake.lock` if it moved (no push)
- `just show` - show flake outputs
- `just info` - show flake metadata

Release helpers (library publishing):

- `just changelog` - update CHANGELOG.md (unreleased)
- `just changelog-full` - regenerate full changelog
- `just release type=patch|minor|major` - release workflow
- `just publish` - build outputs and push to cachix

## Git hook and CI

There is no CI for this repo (the account's Actions budget ran out; the repo is
public, where standard runners are free, so a workflow can come back if wanted).
`just setup-hooks` installs `.githooks/pre-commit`, which formats staged `.nix`
files and then asks `Run nix flake check before committing? [y/N]` when a `.nix`,
`.sh`, `.py`, `.bats` or `.lock` file is staged. Set `HYPRFLAKE_CHECKS=1` to run
it without asking or `HYPRFLAKE_CHECKS=0` to skip it. With no terminal (agents,
scripts) it skips.
