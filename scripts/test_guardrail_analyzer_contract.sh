#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_guardrails.py"
FIXTURE_DIR="$ROOT_DIR/docs/perf/fixtures/npc"

fixtures=(
  "steady.csv"
  "burst.csv"
  "starvation_risk.csv"
  "warmup_rescan.csv"
  "fairness_pass.csv"
)

for fixture in "${fixtures[@]}"; do
  input="$FIXTURE_DIR/$fixture"
  [[ -f "$input" ]] || { echo "[FAIL] missing fixture: $input"; exit 1; }

  expected="$(python3 - "$input" <<'PY'
import csv
import sys

path = sys.argv[1]

overflow_result = "NA"
budget_result = "NA"
warmup_result = "NA"

with open(path, encoding="utf-8", newline="") as f:
    reader = csv.DictReader(f)
    fields = set(reader.fieldnames or [])
    rows = list(reader)

if "overflow_events" in fields:
    running = 0
    overflow = 0
    overflow_result = "FAIL"
    for row in rows:
        if (row.get("lifecycle_state") or "").strip().upper() != "RUNNING":
            continue
        running += 1
        try:
            if int(row.get("overflow_events") or "0") > 0:
                overflow += 1
        except Exception:
            overflow_result = "FAIL"
            break
    else:
        overflow_result = "PASS" if running > 0 and overflow > 0 else "FAIL"

if {"budget_overrun", "deferred_events"}.issubset(fields):
    running = 0
    budget = 0
    deferred = 0
    budget_result = "FAIL"
    for row in rows:
        if (row.get("lifecycle_state") or "").strip().upper() != "RUNNING":
            continue
        running += 1
        try:
            if int(row.get("budget_overrun") or "0") > 0:
                budget += 1
            if int(row.get("deferred_events") or "0") > 0:
                deferred += 1
        except Exception:
            budget_result = "FAIL"
            break
    else:
        budget_result = "PASS" if running > 0 and budget > 0 and deferred > 0 else "FAIL"

req = {"route_cache_warmup_ok", "route_cache_rescan_ok", "route_cache_guardrail_status"}
if req.issubset(fields):
    if not rows:
        warmup_result = "FAIL"
    else:
        tokens = {"1", "true", "TRUE", "pass", "PASS"}
        warmup = all((r.get("route_cache_warmup_ok") or "").strip() in tokens for r in rows)
        rescan = all((r.get("route_cache_rescan_ok") or "").strip() in tokens for r in rows)
        guardrails = all((r.get("route_cache_guardrail_status") or "").strip().upper() == "PASS" for r in rows)
        warmup_result = "PASS" if warmup and rescan and guardrails else "FAIL"

print(f"OVERFLOW_RESULT={overflow_result}")
print(f"BUDGET_RESULT={budget_result}")
print(f"WARMUP_RESULT={warmup_result}")
PY
)"

  actual="$(python3 "$ANALYZER" --input "$input")"

  if [[ "$expected" != "$actual" ]]; then
    echo "[FAIL] mismatch for $fixture"
    echo "expected:"
    printf '%s\n' "$expected"
    echo "actual:"
    printf '%s\n' "$actual"
    exit 1
  fi

  echo "[OK] $fixture"
done

echo "[OK] guardrail analyzer contract test passed"
