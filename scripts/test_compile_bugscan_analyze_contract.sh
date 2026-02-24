#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/compile_bugscan_analyze.py"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Case 1: missing __BUGSCAN_OUTPUT_BEGIN__ marker
LOG_NO_MARKER="$TMP_DIR/no_marker.log"
cat > "$LOG_NO_MARKER" <<'LOG'
__BUGSCAN_SOURCE__=scripts/example.nss
__BUGSCAN_EXIT_CODE__=0
warning: this line should not be parsed as compiler output without marker
LOG

set +e
OUT_NO_MARKER="$(python3 "$ANALYZER" "$LOG_NO_MARKER")"
RC_NO_MARKER=$?
set -e
if [[ $RC_NO_MARKER -eq 0 ]]; then
  echo "[FAIL] expected non-zero status when output marker is missing"
  exit 1
fi
python3 - <<'PY' "$OUT_NO_MARKER"
import json
import sys

payload = json.loads(sys.argv[1])
errors = payload["files"]["scripts/example.nss"]["errors"]
warnings = payload["files"]["scripts/example.nss"]["warnings"]
if not any("missing marker __BUGSCAN_OUTPUT_BEGIN__" in line for line in errors):
    raise SystemExit("[FAIL] missing marker error was not reported")
if warnings:
    raise SystemExit("[FAIL] warnings should be empty when output marker is missing")
PY

# Case 2: invalid __BUGSCAN_EXIT_CODE__ value
LOG_BAD_EXIT="$TMP_DIR/bad_exit.log"
cat > "$LOG_BAD_EXIT" <<'LOG'
__BUGSCAN_SOURCE__=scripts/bad_exit.nss
__BUGSCAN_EXIT_CODE__=abc
__BUGSCAN_OUTPUT_BEGIN__
warning: compiler warning line
LOG

set +e
OUT_BAD_EXIT="$(python3 "$ANALYZER" "$LOG_BAD_EXIT")"
RC_BAD_EXIT=$?
set -e
if [[ $RC_BAD_EXIT -eq 0 ]]; then
  echo "[FAIL] expected non-zero status for invalid exit code"
  exit 1
fi
python3 - <<'PY' "$OUT_BAD_EXIT"
import json
import sys

payload = json.loads(sys.argv[1])
bucket = payload["files"]["scripts/bad_exit.nss"]
errors = bucket["errors"]
if not any("invalid exit code 'abc'" in line for line in errors):
    raise SystemExit("[FAIL] invalid exit code format error was not reported")
if bucket.get("non_zero_exits") != [1]:
    raise SystemExit("[FAIL] invalid exit code should fallback to exit_code=1")
if payload.get("status") != "failed":
    raise SystemExit("[FAIL] summary status should be failed for invalid exit code")
PY

echo "[OK] compile bugscan analyzer contract tests passed"
