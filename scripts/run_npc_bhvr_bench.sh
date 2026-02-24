#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-steady}"
RUNS="${RUNS:-3}"
OUTPUT_ROOT="benchmarks/npc_bhvr_baseline/results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${OUTPUT_ROOT}/${TIMESTAMP}"
RAW_DIR="${OUT_DIR}/raw"
FIXTURE_ROOT="docs/perf/fixtures/npc_bhvr"

mkdir -p "${RAW_DIR}"

case "${SCENARIO}" in
  steady|burst|starvation-risk)
    ;;
  *)
    echo "[ERR] Unknown scenario: ${SCENARIO}" >&2
    echo "Supported scenarios: steady, burst, starvation-risk" >&2
    exit 2
    ;;
esac

if ! [[ "${RUNS}" =~ ^[0-9]+$ ]] || (( RUNS < 1 )); then
  echo "[ERR] Invalid RUNS value: ${RUNS}. RUNS must be an integer >= 1 (example: RUNS=3)." >&2
  exit 2
fi

SOURCE_FIXTURE="${FIXTURE_ROOT}/${SCENARIO//-/_}.csv"
if [[ ! -f "${SOURCE_FIXTURE}" ]]; then
  echo "[ERR] Scenario fixture not found: ${SOURCE_FIXTURE}" >&2
  exit 2
fi

echo "[INFO] Running NPC Bhvr benchmark scaffolding"
echo "[INFO] Scenario: ${SCENARIO}"
echo "[INFO] Runs: ${RUNS}"
echo "[INFO] Output: ${OUT_DIR}"

for i in $(seq 1 "${RUNS}"); do
  echo "[INFO] Run ${i}/${RUNS}"
  cp "${SOURCE_FIXTURE}" "${RAW_DIR}/run_${i}.csv"
done

cat > "${OUT_DIR}/summary.md" <<MD
# NPC Bhvr Baseline Summary

- Timestamp: ${TIMESTAMP}
- Scenario: ${SCENARIO}
- Runs: ${RUNS}

## Analyze

Run gate check for each generated CSV:

\`\`\`bash
python3 scripts/analyze_npc_bhvr_fairness.py --input ${RAW_DIR}/run_1.csv
\`\`\`

## Next steps
1. При наличии runtime telemetry замените fixture-данные в ${RAW_DIR}/run_*.csv.
2. Зафиксируйте pass/fail по gate-метрикам в отчёте perf-итерации.
MD

echo "[OK] Benchmark scaffolding completed: ${OUT_DIR}"
