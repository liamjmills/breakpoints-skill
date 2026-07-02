#!/usr/bin/env bash
# Shared helpers for snag-list capture tests. Mirrors working-style's harness.
NODE="/opt/homebrew/bin/node"
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/snag-capture.js"
FAILED=0

snag_setup() {          # fresh temp SNAG_DIR with an empty denylist
  SNAG_DIR="$(mktemp -d)"
  export SNAG_DIR
  : > "$SNAG_DIR/denylist"
}
snag_teardown() { rm -rf "$SNAG_DIR"; unset SNAG_DIR; }

# build a one-turn transcript fixture: $1=prompt $2=response $3=edited-file(optional) $4=uuid(optional)
make_transcript() {
  local f="$SNAG_DIR/transcript.jsonl" prompt="$1" resp="$2" file="${3:-}" uuid="${4:-a1}"
  {
    printf '{"type":"user","uuid":"u1","isMeta":false,"isSidechain":false,"message":{"role":"user","content":[{"type":"text","text":%s}]}}\n' "$(json "$prompt")"
    if [ -n "$file" ]; then
      printf '{"type":"assistant","uuid":"%s","isMeta":false,"isSidechain":false,"message":{"role":"assistant","content":[{"type":"text","text":%s},{"type":"tool_use","name":"Edit","input":{"file_path":"%s"}}]}}\n' "$uuid" "$(json "$resp")" "$file"
    else
      printf '{"type":"assistant","uuid":"%s","isMeta":false,"isSidechain":false,"message":{"role":"assistant","content":[{"type":"text","text":%s}]}}\n' "$uuid" "$(json "$resp")"
    fi
  } > "$f"
  printf '%s' "$f"
}

json() { printf '%s' "$1" | jq -Rs .; }
payload() { printf '{"transcript_path":"%s","cwd":"%s","hook_event_name":"Stop"}' "$1" "$2"; }
run_capture() { printf '%s' "$1" | "$NODE" "$SCRIPT" capture; }
run_nudge()   { "$NODE" "$SCRIPT" nudge; }

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=1; }
assert_contains()     { grep -qF -- "$2" "$1" 2>/dev/null && pass "$3" || fail "$3"; }
assert_not_contains() { grep -qF -- "$2" "$1" 2>/dev/null && fail "$3" || pass "$3"; }
finish() { snag_teardown; [ "$FAILED" = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }; }
