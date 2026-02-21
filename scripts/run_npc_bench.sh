#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-scenario_a_nominal}"
RUNS="${RUNS:-3}"
OUTPUT_ROOT="benchmarks/npc_baseline/results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${OUTPUT_ROOT}/${TIMESTAMP}"
RAW_DIR="${OUT_DIR}/raw"

mkdir -p "${RAW_DIR}"

case "${SCENARIO}" in
  scenario_a_nominal|scenario_b_combat_spike|scenario_c_recovery)
    ;;
  *)
    echo "[ERR] Unknown scenario: ${SCENARIO}" >&2
    echo "Supported scenarios: scenario_a_nominal, scenario_b_combat_spike, scenario_c_recovery" >&2
    exit 2
    ;;
esac

if ! [[ "${RUNS}" =~ ^[0-9]+$ ]] || (( RUNS < 1 )); then
  echo "[ERR] Invalid RUNS value: ${RUNS}. RUNS must be an integer >= 1 (example: RUNS=3)." >&2
  exit 2
fi

echo "[INFO] Running NPC benchmark"
echo "[INFO] Scenario: ${SCENARIO}"
echo "[INFO] Runs: ${RUNS}"
echo "[INFO] Output: ${OUT_DIR}"

# Заглушка раннера: в боевом окружении заменяется на реальный запуск сервера/стенда.
for i in $(seq 1 "${RUNS}"); do
  echo "[INFO] Run ${i}/${RUNS}"
  cat > "${RAW_DIR}/run_${i}.json" <<JSON
{
  "scenario": "${SCENARIO}",
  "run": ${i},
  "area_tick_p95_ms": null,
  "queue_depth_p99": null,
  "dropped_deferred_pct": null,
  "db_flush_p95_ms": null,
  "notes": "Fill with telemetry export from runtime stand"
}
JSON

done

cat > "${OUT_DIR}/summary.md" <<MD
# NPC Baseline Summary

- Timestamp: ${TIMESTAMP}
- Scenario: ${SCENARIO}
- Runs: ${RUNS}

## Next steps
1. Подставьте реальные метрики из runtime/CI telemetry в файлы ${RAW_DIR}/run_*.json.
2. Сформируйте consolidated report в docs/perf/npc_baseline_report.md.
3. Сравните результаты с последним baseline (не старше 14 дней).
MD

echo "[OK] Benchmark scaffolding completed: ${OUT_DIR}"
