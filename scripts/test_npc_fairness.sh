#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_area_queue_fairness.py"
GATE_ANALYZER="$ROOT_DIR/scripts/analyze_npc_fairness.py"
PASS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/fairness_pass.csv"
STARVATION_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/fairness_starvation_violation.csv"
PAUSE_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/fairness_pause_violation.csv"
RESUME_DRAIN_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/fairness_resume_drain_violation.csv"
DECIMAL_LATENCY_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/steady_decimal_latency.csv"
NON_FINITE_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc/non_finite_latency_fail.csv"

RESULTS=()
LOG_FILE="$(mktemp)"
trap 'rm -f "$LOG_FILE"' EXIT

record_result() {
  local guardrail="$1"
  local scenario_id="$2"
  local status="$3"
  local details="$4"
  RESULTS+=("${guardrail}|${scenario_id}|${status}|${details}")
}

run_expect_pass() {
  local guardrail="$1"
  local scenario_id="$2"
  shift 2
  if "$@" >"$LOG_FILE" 2>&1; then
    record_result "${guardrail}" "${scenario_id}" "PASS" "$(tail -n1 "$LOG_FILE" || echo ok)"
  else
    record_result "${guardrail}" "${scenario_id}" "FAIL" "$(tail -n1 "$LOG_FILE" || echo failed)"
    echo "[DEBUG] log file: $LOG_FILE"
    cat "$LOG_FILE"
    return 1
  fi
}

run_expect_fail() {
  local guardrail="$1"
  local scenario_id="$2"
  shift 2
  if "$@" >"$LOG_FILE" 2>&1; then
    record_result "${guardrail}" "${scenario_id}" "FAIL" "expected failure but command passed"
    echo "[DEBUG] log file: $LOG_FILE"
    cat "$LOG_FILE"
    return 1
  fi
  record_result "${guardrail}" "${scenario_id}" "PASS" "expected failure observed"
}

run_expect_pass "automated_fairness" "steady" \
  python3 "$ANALYZER" \
    --input "$PASS_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

run_expect_fail "automated_fairness" "starvation-risk" \
  python3 "$ANALYZER" \
    --input "$STARVATION_FAIL_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

run_expect_fail "automated_fairness" "burst" \
  python3 "$ANALYZER" \
    --input "$PAUSE_FAIL_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

run_expect_fail "automated_fairness" "burst" \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_FAIL_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

if gate_output="$(python3 "$GATE_ANALYZER" --input "$DECIMAL_LATENCY_FIXTURE")"; then
  if [[ "$gate_output" == *"[OK] NPC Bhvr gate checks passed"* ]]; then
    record_result "tick_budget_degraded" "steady" "PASS" "decimal latency fixture accepted"
  else
    record_result "tick_budget_degraded" "steady" "FAIL" "missing OK marker in gate analyzer output"
    echo "$gate_output"
    exit 1
  fi
else
  record_result "tick_budget_degraded" "steady" "FAIL" "gate analyzer returned non-zero"
  exit 1
fi

non_finite_output="$(python3 "$GATE_ANALYZER" --input "$NON_FINITE_FAIL_FIXTURE" 2>&1 || true)"
if [[ "$non_finite_output" == *"[FAIL] invalid numeric value (row index=1, column name=area_tick_latency_ms, raw value='nan')"* ]]; then
  record_result "tick_budget_degraded" "fault-non-finite-latency" "PASS" "invalid numeric guardrail fired"
else
  record_result "tick_budget_degraded" "fault-non-finite-latency" "FAIL" "expected invalid numeric failure missing"
  echo "$non_finite_output"
  exit 1
fi

printf 'guardrail,scenario_id,status,details\n'
for item in "${RESULTS[@]}"; do
  IFS='|' read -r guardrail scenario_id status details <<<"${item}"
  printf '%s,%s,%s,%s\n' "$guardrail" "$scenario_id" "$status" "$details"
done

echo "[OK] NPC Bhvr fairness analyzer tests passed"
