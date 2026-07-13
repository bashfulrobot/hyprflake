# modules/desktop/update-checks/tests/bump-input.bats
setup() {
  TMP="$(mktemp -d)"; export TMP
  cp "$BATS_TEST_DIRNAME/fixtures/flake.nix" "$TMP/flake.nix"
  mkdir -p "$TMP/bin"

  # Stub resolve-latest: tag -> v2.0.0, sha -> forty 'a's.
  cat >"$TMP/bin/resolve-latest" <<'EOF'
#!/bin/sh
case "$2" in
  tag) echo "v2.0.0" ;;
  sha) echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$TMP/bin/resolve-latest"

  # Stub nix: log invocations instead of touching the network.
  cat >"$TMP/bin/nix" <<'EOF'
#!/bin/sh
echo "nix $*" >>"$TMP/nix.log"
EOF
  chmod +x "$TMP/bin/nix"
  export PATH="$TMP/bin:$PATH"

  SCRIPT="$BATS_TEST_DIRNAME/../bump-input.sh"
}
teardown() { rm -rf "$TMP"; }

@test "tag input: url ref rewritten to latest and re-locked" {
  run bash "$SCRIPT" dank-material-shell "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'github:AvengeMedia/DankMaterialShell/v2.0.0' "$TMP/flake.nix"
  ! grep -q '/v1.5.0' "$TMP/flake.nix"
  grep -q 'flake lock --update-input dank-material-shell' "$TMP/nix.log"
}

@test "sha input: url ref rewritten to latest HEAD sha" {
  run bash "$SCRIPT" dms-emoji-launcher "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'dms-emoji-launcher/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' "$TMP/flake.nix"
}

@test "branch input: no url edit, delegates to update-input" {
  run bash "$SCRIPT" voxtype "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'github:peteonrails/voxtype"' "$TMP/flake.nix"
  grep -q 'flake lock --update-input voxtype' "$TMP/nix.log"
}

@test "already-latest tag: no change, no re-lock" {
  cat >"$TMP/bin/resolve-latest" <<'EOF'
#!/bin/sh
[ "$2" = tag ] && echo "v1.5.0"
EOF
  chmod +x "$TMP/bin/resolve-latest"
  run bash "$SCRIPT" dank-material-shell "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/nix.log" ]
}

@test "unknown input exits non-zero" {
  run bash "$SCRIPT" nope "$TMP/flake.nix"
  [ "$status" -ne 0 ]
}

@test "--skip-branch: branch input is skipped, not re-locked" {
  run bash "$SCRIPT" --skip-branch voxtype "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/nix.log" ]
}

# --- regressions: block-scoped, line-precise rewrite ---

@test "no-url block: errors and leaves other inputs untouched" {
  # follows-only block placed BEFORE a real url block: the buggy version walked
  # past its own closing brace and rewrote sentinel; the fixed version stops at
  # the block boundary and errors.
  cat >"$TMP/flake.nix" <<'EOF'
{
  inputs = {
    followsonly = {
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sentinel.url = "github:owner/sentinel/v1.0.0";
  };
}
EOF
  run bash "$SCRIPT" followsonly "$TMP/flake.nix"
  [ "$status" -ne 0 ]
  # the follows-only block must not have grabbed sentinel's url
  grep -q 'github:owner/sentinel/v1.0.0' "$TMP/flake.nix"
  ! grep -q 'github:owner/sentinel/v2.0.0' "$TMP/flake.nix"
  [ ! -f "$TMP/nix.log" ]
}

@test "duplicate ref: only the requested input's block is rewritten" {
  cat >"$TMP/flake.nix" <<'EOF'
{
  inputs = {
    alpha.url = "github:owner/repo/v1.0.0";
    beta.url = "github:owner/repo/v1.0.0";
  };
}
EOF
  run bash "$SCRIPT" alpha "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q 'alpha.url = "github:owner/repo/v2.0.0"' "$TMP/flake.nix"
  grep -q 'beta.url = "github:owner/repo/v1.0.0"' "$TMP/flake.nix"
  grep -q 'flake lock --update-input alpha' "$TMP/nix.log"
}

@test "commented url: the live line is bumped, the comment left intact" {
  cat >"$TMP/flake.nix" <<'EOF'
{
  inputs = {
    foo = {
      # url = "github:x/y/vOLD";
      url = "github:x/y/v1.0.0";
    };
  };
}
EOF
  run bash "$SCRIPT" foo "$TMP/flake.nix"
  [ "$status" -eq 0 ]
  grep -q '# url = "github:x/y/vOLD";' "$TMP/flake.nix"   # comment untouched
  grep -q '^      url = "github:x/y/v2.0.0";' "$TMP/flake.nix"
  ! grep -q 'github:x/y/v2.0.0";.*#' "$TMP/flake.nix"
}
