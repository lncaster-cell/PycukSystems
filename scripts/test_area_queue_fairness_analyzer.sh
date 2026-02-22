#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_area_queue_fairness.py"
PASS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_sample.csv"
PAUSE_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_violation.csv"
LONG_BURST_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_long_burst.csv"
PAUSE_RESUME_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_resume_fault_injection.csv"
RESUME_DRAIN_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_resume_drain_violation.csv"
INVALID_NUMERIC_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_invalid_numeric.csv"

expect_fail() {
  local description="$1"
  local expected_fragment="$2"
  shift 2

  if [[ "${1:-}" == "--" ]]; then
    shift
  fi

  local output=""
  local status=0

  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    echo "[FAIL] expected failure: $description"
    exit 1
  fi

  if [[ -n "$expected_fragment" ]] && [[ "$output" != *"$expected_fragment"* ]]; then
    echo "[FAIL] expected error output to contain '$expected_fragment' for: $description"
    echo "[INFO] actual output:"
    echo "$output"
    exit 1
  fi

  if [[ "$output" == *"Traceback (most recent call last)"* ]]; then
    echo "[FAIL] unexpected traceback in error output for: $description"
    echo "[INFO] actual output:"
    echo "$output"
    exit 1
  fi
}

# Self-tests cover success path + fail contracts:
# - pause-zero invariant violation
# - minimum resume transition threshold violation
# - post-resume drain threshold violation
# - missing --input path

python3 "$ANALYZER" \
  --input "$PASS_FIXTURE" \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero

expect_fail "pause-zero violation fixture" "" -- \
  python3 "$ANALYZER" \
    --input "$PAUSE_FAIL_FIXTURE" \
    --max-starvation-window 10 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero

python3 "$ANALYZER" \
  --input "$LONG_BURST_FIXTURE" \
  --max-starvation-window 2 \
  --buckets LOW,NORMAL

python3 "$ANALYZER" \
  --input "$PAUSE_RESUME_FIXTURE" \
  --max-starvation-window 3 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero \
  --min-resume-transitions 3 \
  --max-post-resume-drain-ticks 1

expect_fail "resume transition count threshold" "" -- \
  python3 "$ANALYZER" \
    --input "$PAUSE_RESUME_FIXTURE" \
    --max-starvation-window 3 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 4 \
    --max-post-resume-drain-ticks 1

expect_fail "post-resume drain latency threshold" "" -- \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_FAIL_FIXTURE" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 1 \
    --max-post-resume-drain-ticks 1

expect_fail "missing input path" "[FAIL] input file not found" -- \
  python3 "$ANALYZER" \
    --input "$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_missing.csv" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL

expect_fail "input path is directory" "[FAIL] input file not found" -- \
  python3 "$ANALYZER" \
    --input "$ROOT_DIR/docs/perf/fixtures" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL

echo "[OK] analyzer self-tests passed"
