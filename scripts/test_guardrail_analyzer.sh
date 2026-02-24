#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/bench/analyze_single_run.py"
SCHEMA="$ROOT_DIR/docs/perf/analyze_single_run_schema.json"
STARVATION_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/starvation_risk.csv"
WARMUP_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/warmup_rescan.csv"
FAIRNESS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/fairness_pass.csv"

assert_status() {
  local output="$1"
  local section="$2"
  local expected="$3"
  python3 - <<'PY' "$output" "$section" "$expected"
import json
import sys
payload = json.loads(sys.argv[1])
section = sys.argv[2]
expected = sys.argv[3]
actual = payload[section]["status"]
if actual != expected:
    raise SystemExit(f"[FAIL] expected {section}.status={expected}, got {actual}")
PY
}

validate_schema() {
  local output="$1"
  python3 - <<'PY' "$output" "$SCHEMA"
import json
import sys
from pathlib import Path

payload = json.loads(sys.argv[1])
schema = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

required = schema["required"]
for key in required:
    if key not in payload:
        raise SystemExit(f"[FAIL] schema required key missing: {key}")

if payload.get("schema_version") != "1.0.0":
    raise SystemExit("[FAIL] schema_version mismatch")

for section in ("fairness", "overflow", "budget", "warmup"):
    if "status" not in payload.get(section, {}):
        raise SystemExit(f"[FAIL] {section}.status missing")
PY
}

output_starvation="$(python3 "$ANALYZER" --input "$STARVATION_FIXTURE" --max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2)"
validate_schema "$output_starvation"
assert_status "$output_starvation" fairness NA
assert_status "$output_starvation" overflow PASS
assert_status "$output_starvation" budget PASS
assert_status "$output_starvation" warmup NA

output_warmup="$(python3 "$ANALYZER" --input "$WARMUP_FIXTURE" --max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2)"
validate_schema "$output_warmup"
assert_status "$output_warmup" fairness NA
assert_status "$output_warmup" overflow FAIL
assert_status "$output_warmup" budget FAIL
assert_status "$output_warmup" warmup PASS

output_fairness="$(python3 "$ANALYZER" --input "$FAIRNESS_FIXTURE" --max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2)"
validate_schema "$output_fairness"
assert_status "$output_fairness" fairness PASS
assert_status "$output_fairness" overflow NA
assert_status "$output_fairness" budget NA
assert_status "$output_fairness" warmup NA

TMP_BAD="$(mktemp)"
cat > "$TMP_BAD" <<'CSV'
tick,lifecycle_state,overflow_events,budget_overrun,deferred_events,processed_low,processed_normal
1,RUNNING,broken,1,1,1,1
CSV
set +e
output_bad="$(python3 "$ANALYZER" --input "$TMP_BAD" --max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2)"
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  echo "[FAIL] expected non-zero for invalid numeric fixture"
  exit 1
fi
python3 - <<'PY' "$output_bad"
import json
import sys
payload = json.loads(sys.argv[1])
if payload.get("status") != "INVALID":
    raise SystemExit("[FAIL] invalid fixture must return status=INVALID")
if "invalid numeric" not in payload.get("error", ""):
    raise SystemExit("[FAIL] expected invalid numeric error")
PY
rm -f "$TMP_BAD"

echo "[OK] Single-run analyzer contract tests passed"
