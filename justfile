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

# Build all outputs and push to cachix (NOTE: Not needed for module-only flake)
# Cachix is more useful for the consumer (nixerator) which builds actual systems
publish: check
    #!/usr/bin/env bash
    set -euo pipefail
    echo "⚠️  Note: Hyprflake is a module library - cachix is more useful in nixerator"
    echo "   This only caches the formatter, not actual system builds."
    echo ""
    if [ -z "${CACHIX_AUTH_TOKEN:-}" ]; then
        echo "❌ Error: CACHIX_AUTH_TOKEN not set"
        echo "Set it with: export CACHIX_AUTH_TOKEN=<token>"
        exit 1
    fi
    echo "🔨 Building module outputs..."
    # Note: This builds the formatter and validates module structure
    nix build .#formatter.x86_64-linux --print-out-paths | nix run nixpkgs#cachix -- push {{cache_name}}
    echo "✅ Published to cachix cache: {{cache_name}}"

# Get current version from git tags (or default to v0.0.0)
_get-version:
    #!/usr/bin/env bash
    git tag --sort=-v:refname | head -1 || echo "v0.0.0"

# Show current version
version:
    @just _get-version

# Bump version and create release (type: major, minor, patch)
release type="patch": update lint check eval
    #!/usr/bin/env bash
    set -euo pipefail

    # Get current version
    CURRENT=$(git tag --sort=-v:refname | head -1 || echo "v0.0.0")
    echo "📊 Current version: $CURRENT"

    # Remove 'v' prefix for calculation
    CURRENT_NUM="${CURRENT#v}"

    # Parse version components
    IFS='.' read -r -a VERSION <<< "$CURRENT_NUM"
    MAJOR="${VERSION[0]:-0}"
    MINOR="${VERSION[1]:-0}"
    PATCH="${VERSION[2]:-0}"

    # Bump version based on type
    case "{{type}}" in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
        *)
            echo "❌ Error: Invalid release type '{{type}}'. Use: major, minor, or patch"
            exit 1
            ;;
    esac

    NEW_VERSION="v$MAJOR.$MINOR.$PATCH"
    echo "🚀 New version: $NEW_VERSION"

    # Check for uncommitted changes (except flake.lock which was just updated)
    if ! git diff --quiet --exit-code -- . ':!flake.lock'; then
        echo "❌ Error: You have uncommitted changes (excluding flake.lock)"
        git status --short
        exit 1
    fi

    # Commit flake.lock if it was updated
    if ! git diff --quiet --exit-code flake.lock; then
        echo "📝 Committing flake.lock update..."
        git add flake.lock
        git commit -S -m "⬆️ chore(deps): update flake inputs for $NEW_VERSION"
    fi

    # Create signed tag
    echo "🏷️  Creating signed tag $NEW_VERSION..."
    git tag -s "$NEW_VERSION" -m "Release $NEW_VERSION"

    # Push commits and tag
    echo "⬆️  Pushing to GitHub..."
    git push origin main
    git push origin "$NEW_VERSION"

    # Create GitHub release
    echo "📦 Creating GitHub release..."
    gh release create "$NEW_VERSION" --generate-notes

    echo ""
    echo "✅ Release $NEW_VERSION published to GitHub!"
    echo ""
    echo "📋 Next step:"
    echo "  Update nixerator: cd ../nixerator && nix flake lock --update-input hyprflake"

# Create a GitHub release with specific version (manual override)
release-manual version:
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
