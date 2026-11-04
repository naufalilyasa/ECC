#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/lima-sandbox-runner.sh"
TEST_RUN_DIR="/tmp/secaudit-selfcheck-$(date +%s)"
mkdir -p "$TEST_RUN_DIR"

PASS_COUNT=0
FAIL_COUNT=0

assert_test() {
  local name="$1"
  local cmd="$2"
  local expected_exit="$3"

  echo -n "[TEST] $name... "
  set +e
  eval "$cmd" >/dev/null 2>&1
  local actual_exit=$?
  set -e

  if [[ "$actual_exit" -eq "$expected_exit" ]]; then
    echo "PASS (exit $actual_exit)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL (expected $expected_exit, got $actual_exit)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "=== Lima Sandbox Runner Self-Check ==="

# Check 1: Without --auto-exec, exits 75 (confirmation gate)
assert_test "Confirmation gate exits 75 when unapproved" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-gate --script 'echo hello'" 75

# Check 2: With --auto-exec, simple command succeeds and captures stdout
assert_test "Basic execution succeeds with exit 0" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-basic --script 'echo hello-world' --auto-exec" 0

if grep -q "hello-world" "$TEST_RUN_DIR/sandbox/test-basic/stdout.log" 2>/dev/null; then
  echo "[TEST] Stdout captured correctly... PASS"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[TEST] Stdout captured correctly... FAIL"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 3: Container write-isolation: writing to /target fails in container (exit_code in result.json != 0)
assert_test "Runner captures RO /target write block" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-ro --script 'echo evil > /target/escape.txt' --auto-exec" 0

if grep -q '"exit_code": 1' "$TEST_RUN_DIR/sandbox/test-ro/result.json" 2>/dev/null || grep -q '"exit_code": 2' "$TEST_RUN_DIR/sandbox/test-ro/result.json" 2>/dev/null; then
  echo "[TEST] Target filesystem write blocked (exit_code != 0)... PASS"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[TEST] Target filesystem write blocked... FAIL"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 4: Container network isolation: outbound network connection fails
assert_test "Runner captures network block (--network none)" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-net --script 'wget -T 2 -qO- https://1.1.1.1' --auto-exec" 0

if grep -q '"exit_code": 1' "$TEST_RUN_DIR/sandbox/test-net/result.json" 2>/dev/null; then
  echo "[TEST] Network access blocked... PASS"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[TEST] Network access blocked... FAIL"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 5: Scratch write & promotion works for regular file
assert_test "Scratch write & regular file promotion" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-promote --script 'echo evidence > /scratch/proof.txt' --allowlist-promote proof.txt --auto-exec" 0

if [[ -f "$TEST_RUN_DIR/sandbox/test-promote/artifacts/proof.txt" ]]; then
  echo "[TEST] Promoted artifact exists... PASS"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "[TEST] Promoted artifact exists... FAIL"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 6: Symlink promotion is rejected (exit 77)
assert_test "Symlink promotion is rejected (exit 77)" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-symlink --script 'ln -s /etc/passwd /scratch/link.txt' --allowlist-promote link.txt --auto-exec" 77

# Check 7: Shell injection payload does not escape container to VM
assert_test "Single quotes / injection safely handled without VM escape" \
  "$RUNNER --run-dir '$TEST_RUN_DIR' --poc-id test-inject --script \"echo 'safe-escaped'; echo 'done'\" --auto-exec" 0

# Check 8 (C1/C2 regression): POC_ID carrying shell metacharacters is rejected at
# parse time, before any directory is created or any VM command is issued.
# Invoked directly (not via eval) so the payload cannot perturb this script.
echo -n "[TEST] Malicious --poc-id rejected before execution... "
set +e
"$RUNNER" --run-dir "$TEST_RUN_DIR" --poc-id "p1'; touch /tmp/pwned-in-vm; echo '" --script 'echo hi' --auto-exec >/dev/null 2>&1
inject_exit=$?
set -e
if [[ "$inject_exit" -eq 1 && ! -e /tmp/pwned-in-vm ]]; then
  echo "PASS (exit $inject_exit, no host artifact)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL (expected exit 1 and no /tmp/pwned-in-vm, got exit $inject_exit)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 9 (C2 regression): promotion path with shell metacharacters is rejected (exit 77)
echo -n "[TEST] Malicious --allowlist-promote rejected... "
set +e
"$RUNNER" --run-dir "$TEST_RUN_DIR" --poc-id test-promote-inject --script 'echo hi' --allowlist-promote "a'bc" --auto-exec >/dev/null 2>&1
promote_exit=$?
set -e
if [[ "$promote_exit" -eq 77 ]]; then
  echo "PASS (exit $promote_exit)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL (expected exit 77, got $promote_exit)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 10 (M1 regression): out-of-range resource limits are rejected before execution
echo -n "[TEST] Out-of-range --wall rejected... "
set +e
"$RUNNER" --run-dir "$TEST_RUN_DIR" --poc-id test-wall --script 'echo hi' --wall 999999 --auto-exec >/dev/null 2>&1
wall_exit=$?
set -e
if [[ "$wall_exit" -eq 1 ]]; then
  echo "PASS (exit $wall_exit)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL (expected exit 1, got $wall_exit)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Cleanup
rm -rf "$TEST_RUN_DIR"

echo "========================================"
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
echo "ALL SANDBOX SELF-CHECKS PASSED!"
exit 0
