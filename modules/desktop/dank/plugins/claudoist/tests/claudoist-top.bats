# modules/desktop/dank/plugins/claudoist/tests/claudoist-top.bats
# Exercises claudoist-top.sh against a stub curl. The stub prints the body in
# $STUB_BODY and the HTTP status in $STUB_CODE (or exits non-zero when
# $STUB_FAIL is set), and records its arguments so the tests can prove the key
# never appears in a process argument list.
setup() {
  TMP="$(mktemp -d)"
  export TMP
  mkdir -p "$TMP/bin" "$TMP/run"
  cat >"$TMP/bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$TMP/curl-args"
cat >"$TMP/curl-stdin"
[ -n "$STUB_FAIL" ] && exit 7
printf '%s\n%s' "$STUB_BODY" "${STUB_CODE:-200}"
EOF
  chmod +x "$TMP/bin/curl"
  export PATH="$TMP/bin:$PATH"
  export XDG_RUNTIME_DIR="$TMP/run"
  export CLAUDOIST_PORT=47615
  SCRIPT="${BATS_TEST_DIRNAME}/../claudoist-top.sh"
  export SCRIPT
  printf 'SECRETKEY/with+chars' >"$TMP/run/claudoist-token"
}
teardown() { rm -rf "$TMP"; }

@test "missing token file reports no-token" {
  rm -f "$TMP/run/claudoist-token"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .status)" = "no-token" ]
}

@test "unreachable helper reports down" {
  STUB_FAIL=1 run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "401 reports bad-token and 500 reports down" {
  STUB_BODY='[]' STUB_CODE=401 run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "bad-token" ]
  STUB_BODY='[]' STUB_CODE=500 run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "non-numeric port reports down without calling curl" {
  CLAUDOIST_PORT='1"; output = "/x' STUB_BODY='[]' run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-args" ]
}

@test "caps items at 5, keeps the total and cuts titles to 70 characters" {
  long="$(printf 'x%.0s' $(seq 1 120))"
  body="$(jq -nc --arg t "$long" '[range(0;9) | {id: (.|tostring), title: $t, state: "ready", launch: "http://127.0.0.1:47615/launch?id=1"}]')"
  STUB_BODY="$body" run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  [ "$(echo "$output" | jq -r '.items | length')" = "5" ]
  [ "$(echo "$output" | jq -r .total)" = "9" ]
  [ "$(echo "$output" | jq -r '.items[0].title | length')" = "70" ]
}

@test "replaces control whitespace in titles with a space" {
  body='[{"title":"a\nb\tc","state":"ready","launch":"http://127.0.0.1:47615/launch"}]'
  STUB_BODY="$body" run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r '.items[0].title')" = "a b c" ]
}

@test "blanks launch values that do not point at the helper" {
  body='[
    {"title":"a","state":"s","launch":"javascript:alert(1)"},
    {"title":"b","state":"s","launch":"https://example.invalid/x"},
    {"title":"c","state":"s","launch":"-o /tmp/x"},
    {"title":"d","state":"s","launch":"http://127.0.0.1:99999/launch"},
    {"title":"e","state":"s","launch":"http://127.0.0.1:47615/launch?id=1&sig=2"}
  ]'
  STUB_BODY="$body" run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r '[.items[].launch] | map(select(. != "")) | length')" = "1" ]
  [ "$(echo "$output" | jq -r '.items[4].launch')" = "http://127.0.0.1:47615/launch?id=1&sig=2" ]
}

@test "a non-array body reports down" {
  STUB_BODY='{"error":"x"}' run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "the key never appears in curl's arguments and curl ignores user config" {
  STUB_BODY='[]' run bash "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  ! grep -q 'SECRETKEY' "$TMP/curl-args"
  grep -q '^-q$' "$TMP/curl-args"
  grep -q 'noproxy' "$TMP/curl-args"
  # the URL-encoded key travels on stdin only
  grep -q 'SECRETKEY%2Fwith%2Bchars' "$TMP/curl-stdin"
}

@test "only the first line of the token file is used" {
  printf 'LINE1\nLINE2\n' >"$TMP/run/claudoist-token"
  STUB_BODY='[]' run bash "$SCRIPT"
  grep -q 'token=LINE1"' "$TMP/curl-stdin"
}
