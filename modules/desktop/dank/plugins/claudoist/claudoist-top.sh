#!/usr/bin/env bash
# Data source for the DankBar claudoist widget. Prints one JSON object:
#   {"status":"ok|down|no-token|bad-token","total":N,"items":[{"title","state","launch"}]}
# The helper key is read from $XDG_RUNTIME_DIR/claudoist-token (written by the
# claudoist-helper user unit). It is never printed and never placed in a
# process argument list: curl takes its URL from a config on stdin, and the
# key is URL-encoded by jq reading stdin. stderr is discarded so no tool can
# echo the request URL. curl runs with -q and --noproxy so ~/.curlrc and proxy
# variables cannot redirect or trace the key-bearing request.
set -u

port="${CLAUDOIST_PORT:-47615}"
tokfile="${XDG_RUNTIME_DIR:-/nonexistent}/claudoist-token"

emit() { jq -nc --arg s "$1" '{status: $s, total: 0, items: []}'; }

# The port is interpolated into a curl config line, so it must be digits only.
case "$port" in
'' | *[!0-9]*)
  emit down
  exit 0
  ;;
esac

if [ ! -r "$tokfile" ] || [ ! -s "$tokfile" ]; then
  emit no-token
  exit 0
fi

token="$(head -n 1 "$tokfile" | tr -d '\r')"
enc="$(printf '%s' "$token" | jq -rR '@uri')"

# Last line of the response is the HTTP status; the rest is the body.
resp="$(printf 'url = "http://127.0.0.1:%s/top.json?token=%s"\n' "$port" "$enc" |
  curl -q --noproxy '*' -s --max-time 8 --max-filesize 65536 -w '\n%{http_code}' -K - 2>/dev/null)" || {
  emit down
  exit 0
}
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
# content carries another URL never reaches xdg-open.
printf '%s' "$body" | jq -c --arg port "$port" '
  ("^http://(127\\.0\\.0\\.1|localhost):" + $port + "/") as $origin
  | if type == "array" then
    {status: "ok",
     total: length,
     items: (.[0:5] | map({
       title: ((.title // "") | tostring | gsub("[\\n\\r\\t]"; " ")
               | if length > 70 then .[0:69] + "…" else . end),
       state: ((.state // "") | tostring | gsub("[\\n\\r\\t]"; " ") | .[0:40]),
       launch: (if ((.launch // "") | tostring | test($origin)) then .launch else "" end)
     }))}
  else {status: "down", total: 0, items: []} end
' 2>/dev/null || emit down
