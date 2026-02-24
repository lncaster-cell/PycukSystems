#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_guardrails.py"
STARVATION_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/starvation_risk.csv"
WARMUP_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/warmup_rescan.csv"
FAIRNESS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/fairness_pass.csv"

assert_env_value() {
  local output="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(printf '%s\n' "$output" | awk -F= -v k="$key" '$1==k {print $2}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "[FAIL] expected ${key}=${expected}, got '${actual}'"
    echo "$output"
    exit 1
  fi
}

output_starvation="$(python3 "$ANALYZER" --input "$STARVATION_FIXTURE")"
assert_env_value "$output_starvation" OVERFLOW PASS
assert_env_value "$output_starvation" BUDGET PASS
assert_env_value "$output_starvation" WARMUP NA

output_warmup="$(python3 "$ANALYZER" --input "$WARMUP_FIXTURE")"
assert_env_value "$output_warmup" OVERFLOW FAIL
assert_env_value "$output_warmup" BUDGET FAIL
assert_env_value "$output_warmup" WARMUP PASS

output_fairness="$(python3 "$ANALYZER" --input "$FAIRNESS_FIXTURE")"
assert_env_value "$output_fairness" OVERFLOW NA
assert_env_value "$output_fairness" BUDGET NA
assert_env_value "$output_fairness" WARMUP NA

TMP_BAD="$(mktemp)"
cat > "$TMP_BAD" <<'CSV'
tick,lifecycle_state,overflow_events,budget_overrun,deferred_events
1,RUNNING,broken,1,1
CSV
output_bad="$(python3 "$ANALYZER" --input "$TMP_BAD")"
assert_env_value "$output_bad" OVERFLOW FAIL
assert_env_value "$output_bad" BUDGET FAIL
assert_env_value "$output_bad" WARMUP NA
rm -f "$TMP_BAD"

json_output="$(python3 "$ANALYZER" --input "$STARVATION_FIXTURE" --format json)"
python3 - <<'PY' "$json_output"
import json
import sys
payload = json.loads(sys.argv[1])
assert payload["overflow"] == "PASS"
assert payload["budget"] == "PASS"
assert payload["warmup"] == "NA"
PY

echo "[OK] Guardrail analyzer contract tests passed"
