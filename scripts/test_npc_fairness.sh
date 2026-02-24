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
LOG_FILE="/tmp/npc_fairness_check.log"
RUN_RC=0
RUN_LAST_LINE=""

record_result() {
  local guardrail="$1"
  local scenario_id="$2"
  local status="$3"
  local details="$4"
  RESULTS+=("${guardrail}|${scenario_id}|${status}|${details}")
}

run_and_capture() {
  local log_file="$1"
  shift

  set +e
  "$@" >"$log_file" 2>&1
  RUN_RC=$?
  set -e

  RUN_LAST_LINE="$(tail -n1 "$log_file" 2>/dev/null || true)"
  if [[ -z "$RUN_LAST_LINE" ]]; then
    RUN_LAST_LINE="(no output)"
  fi
}

run_expect_pass() {
  run_expect "pass" "$@"
}

run_expect_fail() {
  run_expect "fail" "$@"
}

run_expect() {
  local mode="$1"
  local guardrail="$2"
  local scenario_id="$3"
  shift 3

  run_and_capture "$LOG_FILE" "$@"

  if [[ "$mode" == "pass" ]]; then
    if [[ $RUN_RC -eq 0 ]]; then
      record_result "$guardrail" "$scenario_id" "PASS" "$RUN_LAST_LINE"
      return 0
    fi

    record_result "$guardrail" "$scenario_id" "FAIL" "$RUN_LAST_LINE"
    cat "$LOG_FILE"
    return 1
  fi

  if [[ $RUN_RC -ne 0 ]]; then
    record_result "$guardrail" "$scenario_id" "PASS" "expected failure observed: $RUN_LAST_LINE"
    return 0
  fi

  record_result "$guardrail" "$scenario_id" "FAIL" "expected failure but command passed"
  cat "$LOG_FILE"
  return 1
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

run_and_capture "$LOG_FILE" python3 "$GATE_ANALYZER" --input "$DECIMAL_LATENCY_FIXTURE"
if [[ $RUN_RC -eq 0 ]]; then
  if [[ "$RUN_LAST_LINE" == *"[OK] NPC Bhvr gate checks passed"* ]]; then
    record_result "tick_budget_degraded" "steady" "PASS" "decimal latency fixture accepted"
  else
    record_result "tick_budget_degraded" "steady" "FAIL" "missing OK marker in gate analyzer output"
    cat "$LOG_FILE"
    exit 1
  fi
else
  record_result "tick_budget_degraded" "steady" "FAIL" "gate analyzer returned non-zero"
  cat "$LOG_FILE"
  exit 1
fi

run_and_capture "$LOG_FILE" python3 "$GATE_ANALYZER" --input "$NON_FINITE_FAIL_FIXTURE"
if [[ $RUN_RC -ne 0 ]] && [[ "$RUN_LAST_LINE" == *"[FAIL] invalid numeric value (row index=1, column name=area_tick_latency_ms, raw value='nan')"* ]]; then
  record_result "tick_budget_degraded" "fault-non-finite-latency" "PASS" "invalid numeric guardrail fired"
else
  record_result "tick_budget_degraded" "fault-non-finite-latency" "FAIL" "expected invalid numeric failure missing"
  cat "$LOG_FILE"
  exit 1
fi

printf 'guardrail,scenario_id,status,details\n'
for item in "${RESULTS[@]}"; do
  IFS='|' read -r guardrail scenario_id status details <<<"${item}"
  printf '%s,%s,%s,%s\n' "$guardrail" "$scenario_id" "$status" "$details"
done

echo "[OK] NPC Bhvr fairness analyzer tests passed"
