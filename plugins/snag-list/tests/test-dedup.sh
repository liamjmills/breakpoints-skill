#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
T="$(make_transcript "make the table rows resize" "done" "src/Grid.tsx" "same-uuid")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"  # identical turn again
LOG="$SNAG_DIR/captures.log"
[ "$(wc -l < "$LOG" | tr -d ' ')" = "1" ] && pass "identical turn logged once" || fail "identical turn logged once"
finish
