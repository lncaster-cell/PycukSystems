#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-steady}"
RUNS="${RUNS:-3}"
OUTPUT_ROOT="benchmarks/npc_baseline/results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${OUTPUT_ROOT}/${TIMESTAMP}"
RAW_DIR="${OUT_DIR}/raw"
ANALYSIS_DIR="${OUT_DIR}/analysis"
FIXTURE_ROOT="docs/perf/fixtures/npc"
BASELINE_FILE="docs/perf/npc_baseline_report.md"
BASELINE_META_FILE="${ANALYSIS_DIR}/baseline_meta.json"
SINGLE_RUN_ANALYZER="scripts/bench/analyze_single_run.py"
WRITE_BASELINE_META="scripts/bench/write_baseline_meta.py"
CHECK_BASELINE_FRESHNESS="scripts/bench/check_baseline_freshness.py"
WRITE_GATE_SUMMARY="scripts/bench/write_gate_summary.py"

QUEUE_FLAGS=(
  --max-starvation-window 3
  --enforce-pause-zero
  --max-post-resume-drain-ticks 1
  --min-resume-transitions 2
)

mkdir -p "${RAW_DIR}" "${ANALYSIS_DIR}"

if ! [[ "${RUNS}" =~ ^[0-9]+$ ]] || (( RUNS < 1 )); then
  echo "[ERR] Invalid RUNS value: ${RUNS}. RUNS must be an integer >= 1 (example: RUNS=3)." >&2
  exit 2
fi

resolve_fixture() {
  case "$1" in
    steady) echo "${FIXTURE_ROOT}/steady.csv" ;;
    burst) echo "${FIXTURE_ROOT}/burst.csv" ;;
    starvation-risk) echo "${FIXTURE_ROOT}/starvation_risk.csv" ;;
    overflow-guardrail|tick-budget|tick-budget-degraded) echo "${FIXTURE_ROOT}/starvation_risk.csv" ;;
    fairness-checks) echo "${FIXTURE_ROOT}/fairness_pass.csv" ;;
    warmup-rescan) echo "${FIXTURE_ROOT}/warmup_rescan.csv" ;;
    *) return 1 ;;
  esac
}

is_guardrail_enabled() {
  local profile="$1"
  local guardrail="$2"
  case "${profile}:${guardrail}" in
    steady:fairness) echo "true" ;;
    burst:budget|burst:fairness) echo "true" ;;
    starvation-risk:overflow|starvation-risk:budget|starvation-risk:fairness) echo "true" ;;
    overflow-guardrail:overflow|tick-budget:budget|tick-budget-degraded:budget|fairness-checks:fairness) echo "true" ;;
    warmup-rescan:warmup) echo "true" ;;
    *) echo "false" ;;
  esac
}

summarize_guardrail() {
  local enabled="$1"
  local pass_count="$2"
  local total_count="$3"
  local unavailable_note="$4"

  if [[ "${enabled}" != "true" ]]; then
    echo "N/A|Not part of selected profile"
    return
  fi

  if (( total_count == 0 )); then
    echo "N/A|${unavailable_note}"
    return
  fi

  if (( pass_count == total_count )); then
    echo "PASS|${pass_count}/${total_count} runs passed"
  else
    echo "FAIL|$((total_count-pass_count)) of ${total_count} runs failed"
  fi
}

SOURCE_FIXTURE="$(resolve_fixture "${SCENARIO}" || true)"
if [[ -z "${SOURCE_FIXTURE}" ]]; then
  echo "[ERR] Unknown scenario/profile: ${SCENARIO}" >&2
  echo "Supported values: steady, burst, starvation-risk, overflow-guardrail, tick-budget, tick-budget-degraded, fairness-checks, warmup-rescan" >&2
  exit 2
fi

if [[ ! -f "${SOURCE_FIXTURE}" ]]; then
  echo "[ERR] Scenario fixture not found: ${SOURCE_FIXTURE}" >&2
  exit 2
fi

short_sha="$(git rev-parse --short HEAD 2>/dev/null || true)"
full_sha="$(git rev-parse HEAD 2>/dev/null || true)"
branch_name="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
BASELINE_META_FILE="${BASELINE_META_FILE}" TIMESTAMP="${TIMESTAMP}" SCENARIO="${SCENARIO}" RUNS="${RUNS}" BASELINE_FILE="${BASELINE_FILE}" SHORT_SHA="${short_sha}" FULL_SHA="${full_sha}" BRANCH_NAME="${branch_name}" python3 "${WRITE_BASELINE_META}"

baseline_info="$(python3 "${CHECK_BASELINE_FRESHNESS}" "${BASELINE_FILE}")"
baseline_state="${baseline_info%%|*}"
baseline_note="${baseline_info#*|}"

fairness_runs=0
fairness_pass=0
overflow_runs=0
overflow_pass=0
budget_runs=0
budget_pass=0
warmup_runs=0
warmup_pass=0

for i in $(seq 1 "${RUNS}"); do
  run_csv="${RAW_DIR}/run_${i}.csv"
  run_json="${ANALYSIS_DIR}/run_${i}_single_run.json"

  cp "${SOURCE_FIXTURE}" "${run_csv}"

  python3 "${SINGLE_RUN_ANALYZER}" --input "${run_csv}" "${QUEUE_FLAGS[@]}" >"${run_json}"

  while IFS='=' read -r key value; do
    case "${key}" in
      FAIRNESS_STATUS)
        ((fairness_runs += 1))
        [[ "${value}" == "PASS" ]] && ((fairness_pass += 1))
        ;;
      OVERFLOW_STATUS)
        ((overflow_runs += 1))
        [[ "${value}" == "PASS" ]] && ((overflow_pass += 1))
        ;;
      BUDGET_STATUS)
        ((budget_runs += 1))
        [[ "${value}" == "PASS" ]] && ((budget_pass += 1))
        ;;
      WARMUP_STATUS)
        ((warmup_runs += 1))
        [[ "${value}" == "PASS" ]] && ((warmup_pass += 1))
        ;;
      ERROR)
        echo "[ERR] analyze_single_run.py returned INVALID payload for ${run_csv}" >&2
        exit 2
        ;;
    esac
  done < <(python3 - "$run_json" <<'PY'
import json
import sys

payload = json.loads(open(sys.argv[1], encoding="utf-8").read())
if payload.get("status") != "OK":
    print("ERROR=1")
    raise SystemExit(0)

for name in ("fairness", "overflow", "budget", "warmup"):
    status = payload[name]["status"]
    if status != "NA":
        print(f"{name.upper()}_STATUS={status}")
PY
)

done

overflow_summary="$(summarize_guardrail "$(is_guardrail_enabled "${SCENARIO}" overflow)" "${overflow_pass}" "${overflow_runs}" "overflow_events data absent in fixture")"
budget_summary="$(summarize_guardrail "$(is_guardrail_enabled "${SCENARIO}" budget)" "${budget_pass}" "${budget_runs}" "budget_overrun/deferred_events data absent in fixture")"
fairness_summary="$(summarize_guardrail "$(is_guardrail_enabled "${SCENARIO}" fairness)" "${fairness_pass}" "${fairness_runs}" "processed_* columns absent in fixture")"
warmup_summary="$(summarize_guardrail "$(is_guardrail_enabled "${SCENARIO}" warmup)" "${warmup_pass}" "${warmup_runs}" "route_cache_* columns absent in fixture")"

overflow_status="${overflow_summary%%|*}"; overflow_note="${overflow_summary#*|}"
budget_status="${budget_summary%%|*}"; budget_note="${budget_summary#*|}"
fairness_status="${fairness_summary%%|*}"; fairness_note="${fairness_summary#*|}"
warmup_status="${warmup_summary%%|*}"; warmup_note="${warmup_summary#*|}"

if [[ "${baseline_state}" == "BLOCKED" ]]; then
  if [[ "${overflow_status}" == "PASS" ]]; then overflow_status="BLOCKED"; overflow_note="${overflow_note}; baseline ${baseline_note}"; fi
  if [[ "${budget_status}" == "PASS" ]]; then budget_status="BLOCKED"; budget_note="${budget_note}; baseline ${baseline_note}"; fi
  if [[ "${fairness_status}" == "PASS" ]]; then fairness_status="BLOCKED"; fairness_note="${fairness_note}; baseline ${baseline_note}"; fi
  if [[ "${warmup_status}" == "PASS" ]]; then warmup_status="BLOCKED"; warmup_note="${warmup_note}; baseline ${baseline_note}"; fi
fi

OUT_DIR="${OUT_DIR}" TIMESTAMP="${TIMESTAMP}" SCENARIO="${SCENARIO}" SOURCE_FIXTURE="${SOURCE_FIXTURE}" RUNS="${RUNS}" BASELINE_STATE="${baseline_state}" BASELINE_NOTE="${baseline_note}" BASELINE_FILE="${BASELINE_FILE}" OVERFLOW_STATUS="${overflow_status}" OVERFLOW_PASS="${overflow_pass}" OVERFLOW_RUNS="${overflow_runs}" OVERFLOW_NOTE="${overflow_note}" BUDGET_STATUS="${budget_status}" BUDGET_PASS="${budget_pass}" BUDGET_RUNS="${budget_runs}" BUDGET_NOTE="${budget_note}" FAIRNESS_STATUS="${fairness_status}" FAIRNESS_PASS="${fairness_pass}" FAIRNESS_RUNS="${fairness_runs}" FAIRNESS_NOTE="${fairness_note}" WARMUP_STATUS="${warmup_status}" WARMUP_PASS="${warmup_pass}" WARMUP_RUNS="${warmup_runs}" WARMUP_NOTE="${warmup_note}" python3 - <<'PY' | python3 "${WRITE_GATE_SUMMARY}"
import json
import os

payload = {
    "out_dir": os.environ["OUT_DIR"],
    "timestamp": os.environ["TIMESTAMP"],
    "scenario_id": os.environ["SCENARIO"],
    "source_fixture": os.environ["SOURCE_FIXTURE"],
    "runs": int(os.environ["RUNS"]),
    "baseline": {
        "status": os.environ["BASELINE_STATE"],
        "note": os.environ["BASELINE_NOTE"],
        "reference": os.environ["BASELINE_FILE"],
    },
    "guardrails": {
        "overflow": {"status": os.environ["OVERFLOW_STATUS"], "runs_passed": int(os.environ["OVERFLOW_PASS"]), "runs_total": int(os.environ["OVERFLOW_RUNS"]), "evidence": os.environ["OVERFLOW_NOTE"]},
        "budget": {"status": os.environ["BUDGET_STATUS"], "runs_passed": int(os.environ["BUDGET_PASS"]), "runs_total": int(os.environ["BUDGET_RUNS"]), "evidence": os.environ["BUDGET_NOTE"]},
        "fairness": {"status": os.environ["FAIRNESS_STATUS"], "runs_passed": int(os.environ["FAIRNESS_PASS"]), "runs_total": int(os.environ["FAIRNESS_RUNS"]), "evidence": os.environ["FAIRNESS_NOTE"]},
        "warmup": {"status": os.environ["WARMUP_STATUS"], "runs_passed": int(os.environ["WARMUP_PASS"]), "runs_total": int(os.environ["WARMUP_RUNS"]), "evidence": os.environ["WARMUP_NOTE"]},
    },
}
print(json.dumps(payload, ensure_ascii=False))
PY

cat > "${OUT_DIR}/summary.md" <<MD
# NPC Bhvr Baseline Summary

- Timestamp: ${TIMESTAMP}
- Scenario/profile: ${SCENARIO}
- Source fixture: ${SOURCE_FIXTURE}
- Runs: ${RUNS}
- Baseline reference: ${BASELINE_FILE} (${baseline_state}: ${baseline_note})

## Analyzer post-processing

- analyze_single_run.py (fairness): ${fairness_pass}/${fairness_runs} PASS (when applicable).
- analyze_single_run.py (overflow): ${overflow_pass}/${overflow_runs} PASS (when applicable).
- analyze_single_run.py (budget): ${budget_pass}/${budget_runs} PASS (when applicable).
- analyze_single_run.py (warmup): ${warmup_pass}/${warmup_runs} PASS (when applicable).
- Mandatory fairness flags: ${QUEUE_FLAGS[*]}.

Per-run JSON logs are stored in ${ANALYSIS_DIR}.

## Guardrail checklist (PASS/FAIL/BLOCKED)

| Guardrail | Result | Evidence |
| --- | --- | --- |
| Registry overflow guardrail | ${overflow_status} | ${overflow_note} |
| Tick budget / degraded-mode guardrail | ${budget_status} | ${budget_note} |
| Automated fairness checks | ${fairness_status} | ${fairness_note} |
| Route cache warmup/rescan guardrail | ${warmup_status} | ${warmup_note} |

## Machine-readable artifacts

- ${OUT_DIR}/gate_summary.csv
- ${OUT_DIR}/gate_summary.json
- ${BASELINE_META_FILE}
MD

echo "[OK] Benchmark scaffolding completed: ${OUT_DIR}"
echo "[OK] Gate summary: ${OUT_DIR}/gate_summary.json"

overall_exit=0
for status in "${overflow_status}" "${budget_status}" "${fairness_status}" "${warmup_status}"; do
  if [[ "${status}" == "FAIL" ]]; then
    overall_exit=1
    break
  fi
done

exit "${overall_exit}"
