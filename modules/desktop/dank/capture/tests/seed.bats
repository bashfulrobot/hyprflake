# modules/desktop/dank/capture/tests/seed.bats
setup() {
  TMP="$(mktemp -d)"
  export TMP
  # Stub tool: 'hash' prints sha256 of raw bytes (sufficient for guard tests).
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/dank-settings-tool" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "hash" ] && { sha256sum "$2" | cut -d' ' -f1; exit 0; }
exit 2
EOF
  chmod +x "$TMP/bin/dank-settings-tool"
  export PATH="$TMP/bin:$PATH"
  printf '{"v":1}\n' > "$TMP/effective.json"
  printf '{"v":0}\n' > "$TMP/base.json"
  SEED="${BATS_TEST_DIRNAME}/../seed.sh"
  export SEED
}
teardown() { rm -rf "$TMP"; }

@test "seeds when target absent and records marker" {
  run bash "$SEED" "$TMP/effective.json" "$TMP/base.json" \
      "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [ -f "$TMP/settings.json" ]
  [ -f "$TMP/marker" ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'"v": 1'* ]] || [[ "$output" == *'"v":1'* ]]
}

@test "re-seeds when live matches marker" {
  bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  printf '{"v":2}\n' > "$TMP/effective.json"   # new generation
  run bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'"v":2'* ]] || [[ "$output" == *'"v": 2'* ]]
}

@test "preserves live and warns when marker mismatches" {
  bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  printf '{"v":99,"edited":true}\n' > "$TMP/settings.json"   # GUI edit
  printf '{"v":2}\n' > "$TMP/effective.json"
  run bash "$SEED" "$TMP/effective.json" "$TMP/base.json" "$TMP/settings.json" "$TMP/ref.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"un-captured"* ]]
  run cat "$TMP/settings.json"
  [[ "$output" == *"edited"* ]]
}
