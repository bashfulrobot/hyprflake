#!/usr/bin/env bash
# resolve-latest <owner/repo> <tag|sha>
# Print the latest upstream ref a hyprflake input should pin:
#   tag -> latest release tag (e.g. v1.6.0) from the GitHub releases API
#   sha -> default-branch HEAD commit SHA (commits/HEAD follows the default
#          branch, so the branch name is never hardcoded)
# Public GitHub API over curl, so it runs both in the flake repo (just bump)
# and on a workstation (the update-checks notifier). No auth. On any network
# or parse failure, print nothing and exit non-zero.
set -euo pipefail

repo="${1:?usage: resolve-latest <owner/repo> <tag|sha>}"
mode="${2:?usage: resolve-latest <owner/repo> <tag|sha>}"

api() {
  curl -fsS --max-time 10 -H "Accept: application/vnd.github+json" "$1"
}

case "$mode" in
  tag) api "https://api.github.com/repos/$repo/releases/latest" | jq -er '.tag_name' ;;
  sha) api "https://api.github.com/repos/$repo/commits/HEAD"     | jq -er '.sha' ;;
  *)   echo "resolve-latest: unknown mode '$mode' (want tag|sha)" >&2; exit 2 ;;
esac
