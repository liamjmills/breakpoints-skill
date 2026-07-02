#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"

# (a) a non-UI turn must NOT be captured
snag_setup
T="$(make_transcript "Fix the auth token expiry check, it uses < not <=" "Patched the comparison operator." "src/auth.ts")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"
LOG="$SNAG_DIR/captures.log"
assert_not_contains "$LOG" "auth token expiry" "non-UI turn ignored"
[ ! -s "$LOG" ] && pass "log empty for non-UI turn" || fail "log empty for non-UI turn"
snag_teardown

# (b) a force-phrase turn must be captured even with no keyword
snag_setup
T="$(make_transcript "snag: the export button feels laggy on click" "Noted." )"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"
LOG="$SNAG_DIR/captures.log"
assert_contains "$LOG" '"forced":true'          "force-phrase captured"
assert_contains "$LOG" "export button feels laggy" "forced prompt captured"

finish
