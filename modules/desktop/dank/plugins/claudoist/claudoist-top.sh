#!/usr/bin/env bash
# Data source for the DankBar claudoist widget. Prints one JSON object:
#   {"status":"ok|down|no-token|bad-token","items":[{"title","state","launch"}]}
# The helper key is read from $XDG_RUNTIME_DIR/claudoist-token (written by the
# claudoist-helper user unit). It is never printed and never placed in a
# process argument list: curl takes its URL from a config on stdin, and the
# key is URL-encoded by jq reading stdin. stderr is discarded so no tool can
# echo the request URL.
set -u

port="${CLAUDOIST_PORT:-47615}"
tokfile="${XDG_RUNTIME_DIR:-/nonexistent}/claudoist-token"

emit() { jq -nc --arg s "$1" '{status: $s, items: []}'; }

if [ ! -r "$tokfile" ] || [ ! -s "$tokfile" ]; then
  emit no-token
  exit 0
fi

token="$(tr -d '\r\n' <"$tokfile")"
enc="$(jq -rR '@uri' <<<"$token")"

# Last line of the response is the HTTP status; the rest is the body.
resp="$(printf 'url = "http://127.0.0.1:%s/top.json?token=%s"\n' "$port" "$enc" |
  curl -s --max-time 8 -w '\n%{http_code}' -K - 2>/dev/null)" || {
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

# Titles are cut to 70 characters. Only http(s) launch URLs pass through, so
# xdg-open never receives another scheme or an option-looking string.
jq -c '
  if type == "array" then
    {status: "ok",
     items: (.[0:5] | map({
       title: ((.title // "") | gsub("[\\n\\r\\t]"; " ")
               | if length > 70 then .[0:69] + "…" else . end),
       state: (.state // ""),
       launch: (if ((.launch // "") | test("^https?://")) then .launch else "" end)
     }))}
  else {status: "down", items: []} end
' <<<"$body" 2>/dev/null || emit down
