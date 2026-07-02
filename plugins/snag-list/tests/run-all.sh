#!/usr/bin/env bash
# Run every test-*.sh; exit non-zero if any fails.
cd "$(dirname "$0")"
rc=0
for t in test-*.sh; do
  echo "=== $t ==="
  bash "$t" || rc=1
done
[ "$rc" = 0 ] && echo "==== ALL SUITES PASS ====" || echo "==== SOME SUITES FAILED ===="
exit $rc
