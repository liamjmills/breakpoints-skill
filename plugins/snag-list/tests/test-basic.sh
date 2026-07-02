#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
T="$(make_transcript "Build a styled dropdown instead of a native select" "Done — replaced the native <select> with a styled listbox." "src/Picker.tsx")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"
LOG="$SNAG_DIR/captures.log"
assert_contains "$LOG" '"forced":false'                        "record written (JSONL)"
assert_contains "$LOG" "Build a styled dropdown"               "prompt captured"
assert_contains "$LOG" "styled listbox"                        "excerpt captured"
assert_contains "$LOG" "src/Picker.tsx"                        "edited file captured"
assert_contains "$LOG" '"project":"Internal-Tool"'            "project basename captured"
assert_contains "$LOG" "dropdown"                              "matched keyword recorded"
finish
