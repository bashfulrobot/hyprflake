# Hyprflake justfile - Library maintenance and publishing

# Variables
cache_name := "hyprflake"
github_user := "bashfulrobot"
repo_name := "hyprflake"

# List all available recipes
default:
    @just --list

# === Code Quality ===

# Format all nix files
fmt:
    timeout 30 nix fmt || echo "⚠️  Format timed out - try formatting specific files"

# Lint nix files with statix
lint:
    nix run nixpkgs#statix -- check .

# Fix linting issues automatically
fix:
    nix run nixpkgs#statix -- fix .

# Check flake for errors (validates module structure)
check:
    nix flake check

# Evaluate the module export to verify it's valid
eval:
    nix eval .#nixosModules.default --apply 'x: "Module evaluates successfully"'

# === Dependency Management ===

# Update all flake inputs to latest versions
update:
    nix flake update

# Update a specific input
update-input input:
    nix flake lock --update-input {{input}}

# Show current input versions
inputs:
    @echo "Current flake inputs:"
    @nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | select(.value.locked) | "  \(.key): \(.value.locked.owner // "local")/\(.value.locked.repo // .value.locked.type) @ \(.value.locked.rev[0:7] // .value.locked.narHash[0:10])"'

# Show flake outputs (what consumers will see)
show:
    nix flake show

# Show detailed flake metadata
info:
    nix flake metadata

# === Publishing & Cache ===

# Build all outputs and push to cachix
publish: check
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "${CACHIX_AUTH_TOKEN:-}" ]; then
        echo "❌ Error: CACHIX_AUTH_TOKEN not set"
        echo "Set it with: export CACHIX_AUTH_TOKEN=<token>"
        exit 1
    fi
    echo "🔨 Building module outputs..."
    # Note: This builds the formatter and validates module structure
    nix build .#formatter.x86_64-linux --print-out-paths | cachix push {{cache_name}}
    echo "✅ Published to cachix cache: {{cache_name}}"

# Create a GitHub release (requires gh CLI)
release-github version:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Creating GitHub release {{version}}..."
    git tag -s {{version}} -m "Release {{version}}"
    git push origin {{version}}
    gh release create {{version}} --generate-notes
    echo "✅ Released {{version}} to GitHub"

# === CI/CD Workflows ===

# Run all quality checks (CI pipeline)
ci: fmt lint check eval
    @echo "✅ All CI checks passed - ready to publish!"

# Prepare for new release: update deps, check everything
prepare-release: update lint check eval
    @echo ""
    @echo "✅ Release preparation complete!"
    @echo ""
    @echo "📋 Next steps:"
    @echo "  1. Review flake.lock changes: git diff flake.lock"
    @echo "  2. Commit changes: git commit -S -am 'chore: 🔧 prepare release'"
    @echo "  3. Test in nixerator: Update input and rebuild"
    @echo "  4. Create release: just release-github v1.0.0"
    @echo "  5. Publish cache: just publish"

# === Development ===

# Quick development check (format + validate)
dev: fmt check
    @echo "✅ Development checks passed!"

# Watch for changes and re-check
watch:
    watchexec -e nix -- just dev

# === Git Helpers ===

# Show git status
status:
    @git status

# Show unstaged changes
diff:
    @git diff

# Show staged changes
diff-staged:
    @git diff --staged

# Show what changed in flake.lock
diff-lock:
    @git diff flake.lock

# === Cleanup ===

# Remove build artifacts
clean:
    rm -rf result

# Full cleanup including nix garbage collection
clean-all: clean
    nix-collect-garbage -d
