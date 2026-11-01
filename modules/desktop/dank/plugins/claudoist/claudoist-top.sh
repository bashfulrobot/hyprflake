#!/usr/bin/env bash
# Data source for the DankBar claudoist widget. Prints one JSON object:
#   {"status":"ok|down|no-token|bad-token","total":N,"items":[{"title","state","launch"}]}
# Preferred path: the helper's owner-only unix socket
# $XDG_RUNTIME_DIR/claudoist-helper.sock, which needs no key.
# Fallback for a helper without the socket: TCP with the key read from
# $XDG_RUNTIME_DIR/claudoist-token (written by the claudoist-helper user unit).
# The key is never printed and never placed in a process argument list: curl
# takes its URL from a config on stdin, and the key is URL-encoded by jq reading
# stdin. stderr is discarded so no tool can echo the request URL. curl runs with
# -q and --noproxy so ~/.curlrc and proxy variables cannot redirect or trace
# the request.
set -u

port="${CLAUDOIST_PORT:-47615}"
tokfile="${XDG_RUNTIME_DIR:-/nonexistent}/claudoist-token"
sock="${XDG_RUNTIME_DIR:-/nonexistent}/claudoist-helper.sock"

emit() { jq -nc --arg s "$1" '{status: $s, total: 0, items: []}'; }

# The port is interpolated into a curl config line, so it must be digits only.
case "$port" in
'' | *[!0-9]*)
  emit down
  exit 0
  ;;
esac

# Last line of the response is the HTTP status; the rest is the body.
if [ -S "$sock" ]; then
  # The helper's owner-only unix socket (HELPER_SOCKET). The socket file mode is
  # the authentication, so no key is sent and a process squatting on the TCP
  # port learns nothing. With the socket present, never fall back to TCP: a
  # dead socket reads as "down", not as a reason to send the key elsewhere.
  resp="$(curl -q --noproxy '*' -s --max-time 8 --max-filesize 65536 -w '\n%{http_code}' \
    --unix-socket "$sock" http://localhost/top.json 2>/dev/null)" || {
    emit down
    exit 0
  }
else
  # Older helper without the socket: TCP with the key from the runtime file.
  if [ ! -r "$tokfile" ] || [ ! -s "$tokfile" ]; then
    emit no-token
    exit 0
  fi
  token="$(head -n 1 "$tokfile" | tr -d '\r')"
  enc="$(printf '%s' "$token" | jq -rR '@uri')"
  resp="$(printf 'url = "http://127.0.0.1:%s/top.json?token=%s"\n' "$port" "$enc" |
    curl -q --noproxy '*' -s --max-time 8 --max-filesize 65536 -w '\n%{http_code}' -K - 2>/dev/null)" || {
    emit down
    exit 0
  }
fi
code="${resp##*$'\n'}"
body="${resp%$'\n'*}"

case "$code" in
200) ;;
401 | 403)
  emit bad-token
  exit 0
  ;;
*)
  emit down
  exit 0
  ;;
esac

# Titles are cut to 70 characters. A launch URL passes only when it points at
# the helper itself (127.0.0.1 or localhost on this port), so a task whose
# content carries another URL never reaches xdg-open. A relative /launch?...
# link is resolved against the helper origin.
printf '%s' "$body" | jq -c --arg port "$port" '
  ("^http://(127\\.0\\.0\\.1|localhost):" + $port + "/") as $origin
  | if type == "array" then
    {status: "ok",
     total: length,
     items: (.[0:5] | map({
       title: ((.title // "") | tostring | gsub("[\\n\\r\\t]"; " ")
               | if length > 70 then .[0:69] + "…" else . end),
       state: ((.state // "") | tostring | gsub("[\\n\\r\\t]"; " ") | .[0:40]),
       launch: ((.launch // "") | tostring
                | if test("^/launch\\?") then "http://127.0.0.1:" + $port + .
                  elif test($origin) then . else "" end)
     }))}
  else {status: "down", total: 0, items: []} end
' 2>/dev/null || emit down
