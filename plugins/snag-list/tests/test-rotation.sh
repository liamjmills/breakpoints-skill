#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
# pre-fill the log past the 5MB rotate threshold, then capture once
head -c 5300000 /dev/zero | tr '\0' 'x' > "$SNAG_DIR/captures.log"
T="$(make_transcript "add a tooltip to the icon" "done")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"
ls "$SNAG_DIR/archive/"/captures-*.log >/dev/null 2>&1 && pass "oversized log rotated to archive" || fail "oversized log rotated to archive"
assert_contains "$SNAG_DIR/captures.log" "tooltip" "fresh log holds new capture"
finish
