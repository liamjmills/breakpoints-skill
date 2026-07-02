#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
# UI keyword ("form") present so it captures, plus a secret to strip
T="$(make_transcript "wire the login form; api_key=sk_live_ABC123DEF456 must stay secret" "styled the form")"
run_capture "$(payload "$T" "/Users/liammills/Desktop/Internal-Tool")"
LOG="$SNAG_DIR/captures.log"
assert_contains     "$LOG" "form" "UI turn captured (redaction actually exercised)"
assert_contains     "$LOG" "REDACTED" "secret redacted"
assert_not_contains "$LOG" "sk_live_ABC123DEF456" "raw stripe key not present"
finish
