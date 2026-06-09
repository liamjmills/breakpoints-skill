#!/usr/bin/env bash
# Launch the Breakpoints viewer as a same-origin reverse proxy in front of the user's dev server,
# so scroll-sync and Save PNG work (they're blocked cross-origin). Opens the viewer in the browser.
# Usage: bash launch.sh <dev-url>     e.g. bash launch.sh http://localhost:3000
set -euo pipefail

DEV_URL="${1:-}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # dir holding viewer.html + server.js

if [[ -z "$DEV_URL" ]]; then
  echo "ERROR: no dev URL given. Usage: bash launch.sh http://localhost:3000" >&2
  exit 1
fi
if [[ ! "$DEV_URL" =~ ^https?:// ]]; then
  echo "ERROR: dev URL must start with http:// or https:// (got: $DEV_URL)" >&2
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node not found. The proxy launcher needs Node.js. Install it from https://nodejs.org" >&2
  exit 1
fi

# pick a free port (let the OS choose)
PORT="$(node -e 'const s=require("net").createServer();s.listen(0,"127.0.0.1",()=>{const p=s.address().port;s.close(()=>console.log(p))})')"

# start the proxy in the background
nohup node "$DIR/server.js" "$DEV_URL" "$PORT" "$DIR" >"/tmp/breakpoints-$PORT.log" 2>&1 &
SERVER_PID=$!
sleep 1

# the viewer frames the proxy root ("/"), which is same-origin → sync works
SAME_ORIGIN="http://127.0.0.1:${PORT}/"
ENCODED="$(node -e 'console.log(encodeURIComponent(process.argv[1]))' "$SAME_ORIGIN")"
VIEWER_URL="http://127.0.0.1:${PORT}/__breakpoints__/viewer.html?url=${ENCODED}"

if command -v open >/dev/null 2>&1; then
  open "$VIEWER_URL"
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$VIEWER_URL"
fi

echo "Breakpoints viewer running (proxy mode — scroll-sync + Save PNG work)."
echo "  Previewing: $DEV_URL"
echo "  Viewer:     $VIEWER_URL"
echo "  Server PID: $SERVER_PID  (stop with: kill $SERVER_PID)"
