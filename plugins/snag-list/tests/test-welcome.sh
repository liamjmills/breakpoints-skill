#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
# first session: welcome shown, flag created, nudge suppressed
OUT="$("$NODE" "$SCRIPT" session)"
echo "$OUT" | grep -q "watching for UI/UX niggles" && pass "welcome shown on first session" || fail "welcome shown on first session"
echo "$OUT" | grep -q "snag: <the thing>"          && pass "welcome explains force phrase" || fail "welcome explains force phrase"
echo "$OUT" | grep -q "/snag"                        && pass "welcome mentions /snag" || fail "welcome mentions /snag"
[ -f "$SNAG_DIR/.welcomed" ] && pass ".welcomed flag created" || fail ".welcomed flag created"
# second session: welcome NOT repeated
OUT2="$("$NODE" "$SCRIPT" session)"
echo "$OUT2" | grep -q "watching for UI/UX niggles" && fail "welcome not repeated" || pass "welcome not repeated"
finish
