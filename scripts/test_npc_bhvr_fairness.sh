#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_area_queue_fairness.py"
GATE_ANALYZER="$ROOT_DIR/scripts/analyze_npc_bhvr_fairness.py"
PASS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc_bhvr/fairness_pass.csv"
STARVATION_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc_bhvr/fairness_starvation_violation.csv"
PAUSE_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc_bhvr/fairness_pause_violation.csv"
RESUME_DRAIN_FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc_bhvr/fairness_resume_drain_violation.csv"
DECIMAL_LATENCY_FIXTURE="$ROOT_DIR/docs/perf/fixtures/npc_bhvr/steady_decimal_latency.csv"

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

echo "[OK] NPC Bhvr fairness analyzer tests passed"
