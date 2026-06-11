# modules/desktop/dank/capture/tests/seed.bats
setup() {
  TMP="$(mktemp -d)"
  export TMP
  # Stub tool exercising seed.sh's control flow only. The real, canonical
  # behaviour of merge/hash/equal is covered by tests/test_diff.py.
  #   hash <f>      sha256 of raw bytes
  #   merge <a> <b> desired := contents of <b> (the captured overrides)
  #   equal <a> <b> exit 0 iff identical bytes
  mkdir -p "$TMP/bin"
  # POSIX-sh stub so it execs in the hermetic Nix build sandbox too, where
  # /usr/bin/env is absent but /bin/sh is always present.
  cat >"$TMP/bin/dank-settings-tool" <<'EOF'
#!/bin/sh
case "$1" in
  hash) sha256sum "$2" | cut -d' ' -f1; exit 0 ;;
  merge) cat "$3"; exit 0 ;;
  equal) cmp -s "$2" "$3"; exit $? ;;
esac
exit 2
EOF
  chmod +x "$TMP/bin/dank-settings-tool"
  export PATH="$TMP/bin:$PATH"
  printf '{"base":1}\n' >"$TMP/merged-base.json"
  printf '{"v":1}\n' >"$TMP/overrides.json"
  SEED="${BATS_TEST_DIRNAME}/../seed.sh"
  export SEED
}
teardown() { rm -rf "$TMP"; }

@test "seeds desired (merge of base+overrides) when target absent and records marker" {
  run bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" \
    "$TMP/settings.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [ -f "$TMP/settings.json" ]
  [ -f "$TMP/marker" ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'"v":1'* ]]
}

@test "re-applies desired when live matches marker and overrides changed" {
  bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" "$TMP/settings.json" "$TMP/marker"
  printf '{"v":2}\n' >"$TMP/overrides.json" # captured a new value
  run bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" "$TMP/settings.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'"v":2'* ]]
}

@test "no-op when live matches marker and desired unchanged" {
  bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" "$TMP/settings.json" "$TMP/marker"
  before="$(cat "$TMP/marker")"
  run bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" "$TMP/settings.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [ "$(cat "$TMP/marker")" = "$before" ]
  run cat "$TMP/settings.json"
  [[ "$output" == *'"v":1'* ]]
}

@test "preserves live and warns when marker mismatches (un-captured GUI edit)" {
  bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" "$TMP/settings.json" "$TMP/marker"
  printf '{"v":99,"edited":true}\n' >"$TMP/settings.json" # GUI edit, not captured
  printf '{"v":2}\n' >"$TMP/overrides.json"
  run bash "$SEED" "$TMP/merged-base.json" "$TMP/overrides.json" "$TMP/settings.json" "$TMP/marker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"un-captured"* ]]
  run cat "$TMP/settings.json"
  [[ "$output" == *"edited"* ]]
}
