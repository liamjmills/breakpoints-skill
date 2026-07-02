#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
# below threshold (THRESHOLD=15): 3 records, no baseline -> no nudge
printf '{"x":1}\n%.0s' {1..3} > "$SNAG_DIR/captures.log"
OUT="$(run_nudge)"; [ -z "$OUT" ] && pass "no nudge below threshold" || fail "no nudge below threshold"
# at/above threshold: 20 records -> nudge
printf '{"x":1}\n%.0s' {1..20} > "$SNAG_DIR/captures.log"
OUT="$(run_nudge)"; echo "$OUT" | grep -q "Run /snag" && pass "nudge fires past threshold" || fail "nudge fires past threshold"
# config.json seeded on first capture/config load
rm -f "$SNAG_DIR/config.json"
T="$(make_transcript "add a dropdown" "done")"; run_capture "$(payload "$T" "/x/Tool")"
[ -f "$SNAG_DIR/config.json" ] && pass "config.json seeded on first run" || fail "config.json seeded on first run"
grep -q '"keywords"' "$SNAG_DIR/config.json" && pass "config has keywords" || fail "config has keywords"
finish
