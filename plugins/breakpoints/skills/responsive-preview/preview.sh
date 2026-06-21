#!/usr/bin/env bash
# Single-instance preview through the Breakpoints viewer — ONE viewer per project, always.
# Dedup is keyed on the PROJECT (not the URL), so a floating port or localhost/127.0.0.1
# spelling can't trick it into spawning a second window (the "bunch of them open" problem).
# Usage: bash preview.sh <dev-url> [project-key]
#   <dev-url>     : the running dev server, e.g. http://127.0.0.1:8080/
#   [project-key] : stable id for the project (default: the project dir = $PWD).
#                   Pass the project folder so the key never changes across runs.
set -euo pipefail

DEV_URL="${1:-}"
PROJECT_KEY="${2:-$PWD}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REG="/tmp/breakpoints-instances"     # registry: PID<TAB>PROJECT<TAB>DEV_URL<TAB>VIEWER_URL

if [[ -z "$DEV_URL" ]]; then
  echo "ERROR: no dev URL given. Usage: bash preview.sh <dev-url> [project-key]" >&2
  exit 1
fi

# URLs: lowercase + collapse localhost/127.0.0.1 + drop trailing slash, so spelling can't fork.
norm_url() { printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -e 's#localhost#127.0.0.1#g' -e 's#/*$##'; }
# Project key: absolute path when it's a dir (so cwd vs abspath match). Paths kept verbatim.
if [[ -d "$PROJECT_KEY" ]]; then PROJECT_KEY="$(cd "$PROJECT_KEY" && pwd)"; fi
KEY="${PROJECT_KEY%/}"
DEV_NORM="$(norm_url "$DEV_URL")"
touch "$REG"

# Look up any prior instance for THIS project.
existing="$(awk -F'\t' -v k="$KEY" '$2==k{print}' "$REG" | tail -1 || true)"
if [[ -n "$existing" ]]; then
  e_pid="$(printf '%s' "$existing" | cut -f1)"
  e_url="$(printf '%s' "$existing" | cut -f3)"
  e_view="$(printf '%s' "$existing" | cut -f4)"
  if kill -0 "$e_pid" 2>/dev/null; then
    if [[ "$(norm_url "$e_url")" == "$DEV_NORM" ]]; then
      # Same project, same dev URL, still alive → reuse it.
      echo "Already previewing this project (PID $e_pid) — reusing, not launching another."
      echo "  Viewer: $e_view"
      command -v open >/dev/null 2>&1 && open "$e_view" || true
      exit 0
    fi
    # Same project but the dev URL changed (port floated). Kill the stale viewer so we
    # still end up with exactly ONE for this project, then fall through to relaunch.
    echo "Project's dev URL changed ($e_url → $DEV_URL) — replacing the old viewer (PID $e_pid)."
    kill "$e_pid" 2>/dev/null || true
  fi
  # Drop the old entry (dead, or just-killed) before recording the new one.
  awk -F'\t' -v k="$KEY" '$2!=k' "$REG" > "$REG.tmp" 2>/dev/null && mv "$REG.tmp" "$REG" || true
fi

# Fresh launch via the proxy launcher, then record it for next time.
out="$(bash "$DIR/launch.sh" "$DEV_URL")"
echo "$out"
pid="$(printf '%s' "$out" | sed -n 's/.*Server PID: \([0-9][0-9]*\).*/\1/p' | tail -1)"
vurl="$(printf '%s' "$out" | sed -n 's#.*Viewer:[[:space:]]*\(http[^[:space:]]*\).*#\1#p' | tail -1)"
[[ -n "$pid" && -n "$vurl" ]] && printf '%s\t%s\t%s\t%s\n' "$pid" "$KEY" "$DEV_URL" "$vurl" >> "$REG"
