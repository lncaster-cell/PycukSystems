#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_area_queue_fairness.py"
PASS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_sample.csv"
PAUSE_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_violation.csv"
PARTIAL_PROCESSED_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_zero_partial_processed.csv"
LONG_BURST_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_long_burst.csv"
PAUSE_RESUME_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_resume_fault_injection.csv"
RESUME_DRAIN_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_resume_drain_violation.csv"
RESUME_DRAIN_EOF_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_resume_drain_eof_violation.csv"

expect_fail() {
  local description="$1"
  shift

  if "$@"; then
    echo "[FAIL] expected failure: $description"
    exit 1
  fi
}

python3 "$ANALYZER" \
  --input "$PASS_FIXTURE" \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero

python3 "$ANALYZER" \
  --input "$PARTIAL_PROCESSED_FIXTURE" \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero

expect_fail "pause-zero violation fixture" \
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

expect_fail "resume transition count threshold" \
  python3 "$ANALYZER" \
    --input "$PAUSE_RESUME_FIXTURE" \
    --max-starvation-window 3 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 4 \
    --max-post-resume-drain-ticks 1

expect_fail "post-resume drain latency threshold" \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_FAIL_FIXTURE" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 1 \
    --max-post-resume-drain-ticks 1

expect_fail "post-resume drain latency threshold at EOF" \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_EOF_FAIL_FIXTURE" \
    --max-starvation-window 4 \
    --buckets LOW,NORMAL \
    --enforce-pause-zero \
    --min-resume-transitions 1 \
    --max-post-resume-drain-ticks 0

echo "[OK] analyzer self-tests passed"
