#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="$ROOT_DIR/scripts/analyze_area_queue_fairness.py"
PASS_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_sample.csv"
FAIL_FIXTURE="$ROOT_DIR/docs/perf/fixtures/area_queue_fairness_pause_violation.csv"

python3 "$ANALYZER" \
  --input "$PASS_FIXTURE" \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero

if python3 "$ANALYZER" \
  --input "$FAIL_FIXTURE" \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero; then
  echo "[FAIL] expected pause violation fixture to fail"
  exit 1
fi

echo "[OK] analyzer self-tests passed"
