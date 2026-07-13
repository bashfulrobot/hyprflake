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

# Check code health with deadnix and statix
health:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🏥 Running code health checks..."
    echo ""
    echo "🔍 Checking for unused code with deadnix..."
    nix run nixpkgs#deadnix -- .
    echo ""
    echo "🔍 Running statix linter..."
    nix run nixpkgs#statix -- check .
    echo ""
    echo "✅ Code health check complete"

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

# Advance a tag/SHA-pinned input to its latest upstream ref and re-lock, then
# print the diff to review before committing + `just release`. With no argument,
# every tag/SHA-pinned input is bumped (branch inputs are left untouched; use
# `just update` / `just update-input` for those).
bump input="":
    #!/usr/bin/env bash
    set -euo pipefail
    dir=modules/desktop/update-checks
    export RESOLVE_LATEST="$PWD/$dir/resolve-latest.sh"
    if [ -n "{{input}}" ]; then
      bash "$dir/bump-input.sh" "{{input}}"
    else
      # every top-level input block; bump-input skips branch + already-latest.
      grep -oE '^    [a-z0-9-]+ = \{' flake.nix | sed -E 's/^ +//; s/ = \{//' \
        | while read -r name; do
            bash "$dir/bump-input.sh" --skip-branch "$name" || true
          done
    fi
    git --no-pager diff -- flake.nix flake.lock

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

# Flag when a DMS release carries the Lua-config dispatch fix.
# dank-material-shell is pinned to a master commit because no release tag
# has the fix yet (HyprlandService.qml emitting hl.dsp.* dispatch). This
# compares the pinned rev against the latest release and reports whether
# the release contains the fix, so the pin can move to a tag.
# See docs/workarounds.md.
dms-check:
    #!/usr/bin/env bash
    set -euo pipefail
    repo="AvengeMedia/DankMaterialShell"
    pinned=$(jq -r '.nodes."dank-material-shell".locked.rev' flake.lock)
    latest=$(gh api "repos/$repo/releases/latest" --jq .tag_name)
    echo "Pinned DMS rev : ${pinned:0:12} (master)"
    echo "Latest release : $latest"
    if gh api "repos/$repo/contents/quickshell/Services/HyprlandService.qml?ref=$latest" \
         --jq '.content' | base64 -d | grep -q 'hl.dsp.focus'; then
      echo ""
      echo "RELEASE $latest CONTAINS the Lua dispatch fix."
      echo "Action: pin '$repo/$latest' in flake.nix, and once nixpkgs ships"
      echo "$latest restore 'package = pkgs.dms-shell' in modules/desktop/dank."
    else
      echo ""
      echo "Release $latest does NOT yet contain the fix. Stay on the master pin."
    fi

# === Changelog Management ===

# Generate/update CHANGELOG.md for unreleased changes
changelog:
    #!/usr/bin/env bash
    set -euo pipefail
    CURRENT=$(git tag --sort=-v:refname | head -1 || echo "v0.0.0")
    echo "📝 Generating changelog from $CURRENT to HEAD..."
    if [ -f CHANGELOG.md ]; then
        git cliff "$CURRENT..HEAD" --unreleased --prepend CHANGELOG.md
    else
        git cliff "$CURRENT..HEAD" --unreleased > CHANGELOG.md
    fi
    echo "✅ CHANGELOG.md updated"

# Generate full changelog from all history
changelog-full:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📝 Generating full changelog from all history..."
    git cliff --output CHANGELOG.md
    echo "✅ Full CHANGELOG.md generated"

# Preview changelog for next release without writing to file
changelog-preview:
    #!/usr/bin/env bash
    CURRENT=$(git tag --sort=-v:refname | head -1 || echo "v0.0.0")
    echo "📝 Preview of changes from $CURRENT to HEAD:"
    echo ""
    git cliff "$CURRENT..HEAD" --unreleased

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

    # Check for uncommitted changes (except flake.lock and CHANGELOG.md which will be updated)
    if ! git diff --quiet --exit-code -- . ':!flake.lock' ':!CHANGELOG.md'; then
        echo "❌ Error: You have uncommitted changes (excluding flake.lock and CHANGELOG.md)"
        git status --short
        exit 1
    fi

    # Generate changelog for the new version
    echo "📝 Generating changelog..."
    if [ -f CHANGELOG.md ]; then
        # Update existing changelog by prepending new version
        git cliff "$CURRENT..HEAD" --tag "$NEW_VERSION" --prepend CHANGELOG.md 2>/dev/null || {
            echo "⚠️  Warning: git-cliff failed, generating fresh changelog"
            git cliff "$CURRENT..HEAD" --tag "$NEW_VERSION" > CHANGELOG.md
        }
    else
        # Create new changelog
        git cliff "$CURRENT..HEAD" --tag "$NEW_VERSION" > CHANGELOG.md
    fi

    # Extract the new version section for GitHub release notes
    echo "📋 Extracting release notes..."
    RELEASE_NOTES=$(git cliff "$CURRENT..HEAD" --tag "$NEW_VERSION" --strip header 2>/dev/null || git cliff "$CURRENT..HEAD" --tag "$NEW_VERSION")

    # Commit changes (flake.lock and CHANGELOG.md)
    NEEDS_COMMIT=false
    if ! git diff --quiet --exit-code flake.lock; then
        echo "📝 Staging flake.lock..."
        git add flake.lock
        NEEDS_COMMIT=true
    fi
    if ! git diff --quiet --exit-code CHANGELOG.md; then
        echo "📝 Staging CHANGELOG.md..."
        git add CHANGELOG.md
        NEEDS_COMMIT=true
    fi

    if [ "$NEEDS_COMMIT" = true ]; then
        echo "💾 Committing changes..."
        git commit -S -m "⬆️ chore(release): prepare $NEW_VERSION

    - Update flake inputs
    - Update CHANGELOG.md"
    fi

    # Create signed tag
    echo "🏷️  Creating signed tag $NEW_VERSION..."
    git tag -s "$NEW_VERSION" -m "Release $NEW_VERSION"

    # Push commits and tag
    echo "⬆️  Pushing to GitHub..."
    git push origin main
    git push origin "$NEW_VERSION"

    # Create GitHub release with changelog
    echo "📦 Creating GitHub release..."
    echo "$RELEASE_NOTES" | gh release create "$NEW_VERSION" --notes-file -

    echo ""
    echo "✅ Release $NEW_VERSION published to GitHub!"
    echo ""
    echo "📋 Next step:"
    echo "  Update nixerator: cd ../nixerator && nix flake lock --update-input hyprflake"

# Create a GitHub release with specific version (manual override)
release-manual version:
    #!/usr/bin/env bash
    set -euo pipefail

    # Get previous version for changelog range
    CURRENT=$(git tag --sort=-v:refname | head -1 || echo "v0.0.0")
    echo "📊 Previous version: $CURRENT"
    echo "🚀 New version: {{version}}"

    # Generate changelog for the new version
    echo "📝 Generating changelog..."
    if [ -f CHANGELOG.md ]; then
        git cliff "$CURRENT..HEAD" --tag "{{version}}" --prepend CHANGELOG.md 2>/dev/null || {
            echo "⚠️  Warning: git-cliff failed, generating fresh changelog"
            git cliff "$CURRENT..HEAD" --tag "{{version}}" > CHANGELOG.md
        }
    else
        git cliff "$CURRENT..HEAD" --tag "{{version}}" > CHANGELOG.md
    fi

    # Extract release notes
    echo "📋 Extracting release notes..."
    RELEASE_NOTES=$(git cliff "$CURRENT..HEAD" --tag "{{version}}" --strip header 2>/dev/null || git cliff "$CURRENT..HEAD" --tag "{{version}}")

    # Commit CHANGELOG.md if changed
    if ! git diff --quiet --exit-code CHANGELOG.md; then
        echo "📝 Committing CHANGELOG.md..."
        git add CHANGELOG.md
        git commit -S -m "⬆️ chore(release): update changelog for {{version}}"
        git push origin main
    fi

    # Create signed tag
    echo "🏷️  Creating signed tag {{version}}..."
    git tag -s {{version}} -m "Release {{version}}"
    git push origin {{version}}

    # Create GitHub release with changelog
    echo "📦 Creating GitHub release..."
    echo "$RELEASE_NOTES" | gh release create {{version}} --notes-file -

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

# Pull with tailscale restart (resolves conflicts from tailscale file locks)
pull-conflict:
    @echo "🔄 Pulling with tailscale restart..."
    @sudo tailscale down && git stash && git pull && git stash clear && sudo tailscale up --ssh --accept-dns

# Show recent commits (default: 7 days)
[group('git')]
log days="7":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📜 Commits from last {{days}} days:"
    echo "Total: $(git rev-list --count --since='{{days}} days ago' HEAD)"
    echo "===================="
    git log --since="{{days}} days ago" --pretty=format:"%h - %an: %s (%cr)" --graph

# Hard reset with cleanup
[group('git')]
reset-hard:
    @echo "⚠️  Hard reset with file cleanup..."
    @git fetch
    @git reset --hard HEAD
    @git clean -fd
    @git pull

# Smart sync: detects git state and pushes, resets, or warns as needed
[group('git')]
sync-git:
    #!/usr/bin/env bash
    set -euo pipefail

    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Pause syncthing during git operations
    systemctl --user stop syncthing || true
    trap 'systemctl --user start syncthing || true' EXIT

    git fetch origin

    local_only=$(git log "origin/$current_branch..$current_branch" --oneline 2>/dev/null || true)
    remote_only=$(git log "$current_branch..origin/$current_branch" --oneline 2>/dev/null || true)

    if [[ -n "$local_only" && -n "$remote_only" ]]; then
        echo "⚠️  Diverged — local and remote both have commits:"
        echo ""
        echo "Local:"
        echo "$local_only"
        echo ""
        echo "Remote:"
        echo "$remote_only"
        echo ""
        echo "Resolve manually (rebase, merge, or force-push)."
        exit 1

    elif [[ -n "$local_only" ]]; then
        echo "⬆️  Pushing unpushed commits..."
        git push origin "$current_branch"
        echo "✅ Pushed to origin/$current_branch"

    elif [[ -n "$remote_only" ]]; then
        echo "⬇️  Aligning git state with remote..."
        git reset "origin/$current_branch"
        echo "✅ Git state aligned with origin/$current_branch"

    else
        echo "✅ Already in sync with origin/$current_branch"
    fi

    git status --short

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
