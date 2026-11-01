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
# Only the TCP path feeds a config on stdin (-K -); reading stdin otherwise
# would wait on the test runner.
case " $* " in *" -K "*) cat >"$TMP/curl-stdin" ;; esac
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

make_socket() {
  python3 -c 'import socket, sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])' "$TMP/run/claudoist-helper.sock"
}

@test "uses the unix socket when present and sends no key" {
  make_socket
  rm -f "$TMP/run/claudoist-token"
  STUB_BODY='[{"title":"a","state":"s","launch":"http://127.0.0.1:47615/launch?id=1"}]' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  [ "$(echo "$output" | jq -r '.items[0].launch')" = "http://127.0.0.1:47615/launch?id=1" ]
  grep -q -- '--unix-socket' "$TMP/curl-args"
  grep -q "$TMP/run/claudoist-helper.sock" "$TMP/curl-args"
  grep -q 'http://localhost/top.json' "$TMP/curl-args"
  ! grep -q 'token' "$TMP/curl-args"
  [ ! -e "$TMP/curl-stdin" ]
}

@test "the socket wins when the token file is present too" {
  make_socket
  STUB_BODY='[]' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  [ ! -e "$TMP/curl-stdin" ]
  ! grep -q 'SECRETKEY' "$TMP/curl-args"
}

@test "a symlink at the socket path reads as down and curl is not called" {
  make_socket
  mv "$TMP/run/claudoist-helper.sock" "$TMP/real.sock"
  ln -s "$TMP/real.sock" "$TMP/run/claudoist-helper.sock"
  STUB_BODY='[]' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-args" ]
}

@test "a regular file at the socket path reads as down and curl is not called" {
  : >"$TMP/run/claudoist-helper.sock"
  STUB_BODY='[]' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-args" ]
}

@test "require-socket: no socket reads as down and the key is never read or sent" {
  STUB_BODY='[]' CLAUDOIST_REQUIRE_SOCKET=1 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-args" ]
  [ ! -e "$TMP/curl-stdin" ]
}

@test "require-socket: a socket still works" {
  make_socket
  STUB_BODY='[]' CLAUDOIST_REQUIRE_SOCKET=1 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
}

@test "a custom socket name is used, and a name with a slash is refused" {
  python3 -c 'import socket, sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])' "$TMP/run/other.sock"
  STUB_BODY='[]' CLAUDOIST_SOCKET_NAME=other.sock run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  grep -q "$TMP/run/other.sock" "$TMP/curl-args"
  rm -f "$TMP/curl-args"
  STUB_BODY='[]' CLAUDOIST_SOCKET_NAME=../x run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-args" ]
}

@test "a dead socket reads as down and never falls back to TCP" {
  make_socket
  STUB_FAIL=1 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-stdin" ]
  ! grep -q '127.0.0.1' "$TMP/curl-args"
}

@test "an HTTP error on the socket reads as down" {
  make_socket
  STUB_BODY='[]' STUB_CODE=502 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "missing token file reports no-token" {
  rm -f "$TMP/run/claudoist-token"
  run bash -euo pipefail "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .status)" = "no-token" ]
}

@test "unreachable helper reports down" {
  STUB_FAIL=1 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "401 reports bad-token and 500 reports down" {
  STUB_BODY='[]' STUB_CODE=401 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "bad-token" ]
  STUB_BODY='[]' STUB_CODE=500 run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "non-numeric port reports down without calling curl" {
  CLAUDOIST_PORT='1"; output = "/x' STUB_BODY='[]' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
  [ ! -e "$TMP/curl-args" ]
}

@test "caps items at 5, keeps the total and cuts titles to 70 characters" {
  long="$(printf 'x%.0s' $(seq 1 120))"
  body="$(jq -nc --arg t "$long" '[range(0;9) | {id: (.|tostring), title: $t, state: "ready", launch: "http://127.0.0.1:47615/launch?id=1"}]')"
  STUB_BODY="$body" run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  [ "$(echo "$output" | jq -r '.items | length')" = "5" ]
  [ "$(echo "$output" | jq -r .total)" = "9" ]
  [ "$(echo "$output" | jq -r '.items[0].title | length')" = "70" ]
}

@test "replaces control whitespace in titles with a space" {
  body='[{"title":"a\nb\tc","state":"ready","launch":"http://127.0.0.1:47615/launch"}]'
  STUB_BODY="$body" run bash -euo pipefail "$SCRIPT"
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
  STUB_BODY="$body" run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r '[.items[].launch] | map(select(. != "")) | length')" = "1" ]
  [ "$(echo "$output" | jq -r '.items[4].launch')" = "http://127.0.0.1:47615/launch?id=1&sig=2" ]
}

@test "resolves a relative /launch link against the helper origin" {
  body='[{"title":"a","state":"s","launch":"/launch?id=1&sig=2"}]'
  STUB_BODY="$body" run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r '.items[0].launch')" = "http://127.0.0.1:47615/launch?id=1&sig=2" ]
}

@test "a non-array body reports down" {
  STUB_BODY='{"error":"x"}' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "down" ]
}

@test "the key never appears in curl's arguments and curl ignores user config" {
  STUB_BODY='[]' run bash -euo pipefail "$SCRIPT"
  [ "$(echo "$output" | jq -r .status)" = "ok" ]
  ! grep -q 'SECRETKEY' "$TMP/curl-args"
  grep -q '^-q$' "$TMP/curl-args"
  grep -q 'noproxy' "$TMP/curl-args"
  # the URL-encoded key travels on stdin only
  grep -q 'SECRETKEY%2Fwith%2Bchars' "$TMP/curl-stdin"
}

@test "only the first line of the token file is used" {
  printf 'LINE1\nLINE2\n' >"$TMP/run/claudoist-token"
  STUB_BODY='[]' run bash -euo pipefail "$SCRIPT"
  grep -q 'token=LINE1"' "$TMP/curl-stdin"
}
