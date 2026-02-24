#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_area_queue_fairness.py"
PASS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_sample.csv"
PARTIAL_PROCESSED_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_zero_partial_processed.csv"
PAUSE_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_violation.csv"
LONG_BURST_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_long_burst.csv"
PAUSE_RESUME_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_resume_fault_injection.csv"
RESUME_DRAIN_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_resume_drain_violation.csv"
RESUME_DRAIN_EOF_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_resume_drain_eof_violation.csv"
NO_RUNNING_ROWS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_no_running_rows.csv"

RESULTS=()
LOG_FILE="/tmp/area_queue_check.log"
RUN_RC=0
RUN_LAST_LINE=""

record_result() {
  local guardrail="$1"
  local scenario_id="$2"
  local status="$3"
  local details="$4"
  RESULTS+=("${guardrail}|${scenario_id}|${status}|${details}")
}

run_expect_pass() {
  run_expect "pass" "$@"
}

run_expect_fail() {
  run_expect "fail" "$@"
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
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero

# Этот fixture должен проходить: инвариант pause-zero разрешает частичную обработку
# только до входа в pause, а при paused=true processed_sum обязан оставаться нулём.
run_expect_pass "automated_fairness" "steady-partial" \
  python3 "$ANALYZER" \
  --input "$PARTIAL_PROCESSED_FIXTURE" \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero

run_expect_fail "automated_fairness" "fault-pause-zero" \
  python3 "$ANALYZER" \
    --input "$PAUSE_FAIL_FIXTURE" \
    --max-starvation-window 10 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero

run_expect_pass "automated_fairness" "burst" \
  python3 "$ANALYZER" \
  --input "$LONG_BURST_FIXTURE" \
  --max-starvation-window 2 \
  --buckets LOW,NORMAL

run_expect_pass "automated_fairness" "pause-resume" \
  python3 "$ANALYZER" \
  --input "$PAUSE_RESUME_FIXTURE" \
  --max-starvation-window 3 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero \
  --min-resume-transitions 3 \
  --max-post-resume-drain-ticks 1

run_expect_fail "automated_fairness" "fault-resume-transitions" \
  python3 "$ANALYZER" \
    --input "$PAUSE_RESUME_FIXTURE" \
    --max-starvation-window 3 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 4 \
    --max-post-resume-drain-ticks 1

run_expect_fail "automated_fairness" "fault-resume-drain" \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_FAIL_FIXTURE" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 1 \
    --max-post-resume-drain-ticks 1

run_expect_fail "automated_fairness" "fault-resume-drain-eof" \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_EOF_FAIL_FIXTURE" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 1 \
    --max-post-resume-drain-ticks 0

run_expect_fail "automated_fairness" "fault-no-running" \
  python3 "$ANALYZER" \
    --input "$NO_RUNNING_ROWS_FIXTURE" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL

printf "guardrail,scenario_id,status,details\n"
for item in "${RESULTS[@]}"; do
  IFS='|' read -r guardrail scenario_id status details <<<"${item}"
  printf "%s,%s,%s,%s\n" "$guardrail" "$scenario_id" "$status" "$details"
done

echo "[OK] analyzer self-tests passed"
