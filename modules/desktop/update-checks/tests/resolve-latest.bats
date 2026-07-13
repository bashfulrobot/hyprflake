# modules/desktop/update-checks/tests/resolve-latest.bats
setup() {
  TMP="$(mktemp -d)"; export TMP
  mkdir -p "$TMP/bin"
  # Stub curl: canned JSON keyed off the request URL (the last argument).
  cat >"$TMP/bin/curl" <<'EOF'
#!/bin/sh
for a in "$@"; do url="$a"; done
case "$url" in
  *"/releases/latest") printf '{"tag_name":"v9.9.9"}'; exit 0 ;;
  *"/commits/HEAD")    printf '{"sha":"abc123def456abc123def456abc123def456abcd"}'; exit 0 ;;
  *) exit 22 ;;
esac
EOF
  chmod +x "$TMP/bin/curl"
  export PATH="$TMP/bin:$PATH"
  SCRIPT="$BATS_TEST_DIRNAME/../resolve-latest.sh"
}
teardown() { rm -rf "$TMP"; }

@test "tag mode prints the latest release tag" {
  run bash "$SCRIPT" owner/repo tag
  [ "$status" -eq 0 ]
  [ "$output" = "v9.9.9" ]
}

@test "sha mode prints the default-branch HEAD sha" {
  run bash "$SCRIPT" owner/repo sha
  [ "$status" -eq 0 ]
  [ "$output" = "abc123def456abc123def456abc123def456abcd" ]
}

@test "unknown mode exits 2" {
  run bash "$SCRIPT" owner/repo branch
  [ "$status" -eq 2 ]
}

@test "network failure exits non-zero with no stdout" {
  cat >"$TMP/bin/curl" <<'EOF'
#!/bin/sh
exit 22
EOF
  chmod +x "$TMP/bin/curl"
  run bash "$SCRIPT" owner/repo tag
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}
