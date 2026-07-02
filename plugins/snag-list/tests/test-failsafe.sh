#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
snag_setup
# garbage stdin, missing transcript, empty payload — none may error
printf 'not json at all' | "$NODE" "$SCRIPT" capture; rc=$?; [ "$rc" = 0 ] && pass "garbage stdin exits 0" || fail "garbage stdin exits 0"
run_capture '{"transcript_path":"/nope/missing.jsonl","cwd":"/x"}'; [ "$?" = 0 ] && pass "missing transcript exits 0" || fail "missing transcript exits 0"
run_capture '{}'; [ "$?" = 0 ] && pass "empty payload exits 0" || fail "empty payload exits 0"
"$NODE" "$SCRIPT" capture < /dev/null; [ "$?" = 0 ] && pass "no stdin exits 0" || fail "no stdin exits 0"
finish
