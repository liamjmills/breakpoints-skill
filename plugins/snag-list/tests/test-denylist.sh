#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
echo "/Users/liammills/Desktop/Secret-Repo" > "$SNAG_DIR/denylist"
T="$(make_transcript "build a modal dialog" "done")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Secret-Repo")"
LOG="$SNAG_DIR/captures.log"
[ ! -s "$LOG" ] && pass "denylisted cwd not captured" || fail "denylisted cwd not captured"
finish
