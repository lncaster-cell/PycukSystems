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
  --buckets LOW,NORMAL \
  --max-starvation-window 3 \
  --enforce-pause-zero \
  --max-post-resume-drain-ticks 1 \
  --min-resume-transitions 2

expect_fail "starvation window violation" \
  python3 "$ANALYZER" \
    --input "$STARVATION_FAIL_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

expect_fail "pause-zero violation" \
  python3 "$ANALYZER" \
    --input "$PAUSE_FAIL_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

expect_fail "post-resume drain latency violation" \
  python3 "$ANALYZER" \
    --input "$RESUME_DRAIN_FAIL_FIXTURE" \
    --buckets LOW,NORMAL \
    --max-starvation-window 3 \
    --enforce-pause-zero \
    --max-post-resume-drain-ticks 1 \
    --min-resume-transitions 2

gate_output="$(python3 "$GATE_ANALYZER" --input "$DECIMAL_LATENCY_FIXTURE")"
echo "$gate_output"
if [[ "$gate_output" != *"[OK] NPC Bhvr gate checks passed"* ]]; then
  echo "[FAIL] expected [OK] for decimal latency fixture"
  exit 1
fi

non_finite_output="$(python3 "$GATE_ANALYZER" --input "$NON_FINITE_FAIL_FIXTURE" 2>&1 || true)"
echo "$non_finite_output"
if [[ "$non_finite_output" != *"[FAIL] invalid numeric value (row index=1, column name=area_tick_latency_ms, raw value='nan')"* ]]; then
  echo "[FAIL] expected invalid numeric value for non-finite input"
  exit 1
fi

echo "[OK] NPC Bhvr fairness analyzer tests passed"
