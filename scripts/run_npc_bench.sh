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
NPC_ANALYZER="scripts/analyze_npc_fairness.py"
QUEUE_ANALYZER="scripts/analyze_area_queue_fairness.py"

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
    steady)
      echo "${FIXTURE_ROOT}/steady.csv"
      ;;
    burst)
      echo "${FIXTURE_ROOT}/burst.csv"
      ;;
    starvation-risk)
      echo "${FIXTURE_ROOT}/starvation_risk.csv"
      ;;
    overflow-guardrail)
      echo "${FIXTURE_ROOT}/starvation_risk.csv"
      ;;
    tick-budget|tick-budget-degraded)
      echo "${FIXTURE_ROOT}/starvation_risk.csv"
      ;;
    fairness-checks)
      echo "${FIXTURE_ROOT}/fairness_pass.csv"
      ;;
    *)
      return 1
      ;;
  esac
}

profile_guardrail_status() {
  local profile="$1"
  local overflow_status="$2"
  local budget_status="$3"
  local fairness_status="$4"
  local overflow_note="$5"
  local budget_note="$6"
  local fairness_note="$7"

  case "${profile}" in
    overflow-guardrail)
      echo "| Registry overflow guardrail | ${overflow_status} | ${overflow_note} |"
      echo "| Tick budget / degraded-mode guardrail | N/A | Not part of overflow profile. |"
      echo "| Automated fairness checks | N/A | Not part of overflow profile. |"
      ;;
    tick-budget|tick-budget-degraded)
      echo "| Registry overflow guardrail | N/A | Not part of tick-budget profile. |"
      echo "| Tick budget / degraded-mode guardrail | ${budget_status} | ${budget_note} |"
      echo "| Automated fairness checks | N/A | Not part of tick-budget profile. |"
      ;;
    fairness-checks)
      echo "| Registry overflow guardrail | N/A | Not part of fairness profile. |"
      echo "| Tick budget / degraded-mode guardrail | N/A | Not part of fairness profile. |"
      echo "| Automated fairness checks | ${fairness_status} | ${fairness_note} |"
      ;;
    *)
      echo "| Registry overflow guardrail | ${overflow_status} | ${overflow_note} |"
      echo "| Tick budget / degraded-mode guardrail | ${budget_status} | ${budget_note} |"
      echo "| Automated fairness checks | ${fairness_status} | ${fairness_note} |"
      ;;
  esac
}

SOURCE_FIXTURE="$(resolve_fixture "${SCENARIO}" || true)"
if [[ -z "${SOURCE_FIXTURE}" ]]; then
  echo "[ERR] Unknown scenario/profile: ${SCENARIO}" >&2
  echo "Supported values: steady, burst, starvation-risk, overflow-guardrail, tick-budget, tick-budget-degraded, fairness-checks" >&2
  exit 2
fi

if [[ ! -f "${SOURCE_FIXTURE}" ]]; then
  echo "[ERR] Scenario fixture not found: ${SOURCE_FIXTURE}" >&2
  exit 2
fi

echo "[INFO] Running NPC Bhvr benchmark scaffolding"
echo "[INFO] Scenario/profile: ${SCENARIO}"
echo "[INFO] Runs: ${RUNS}"
echo "[INFO] Output: ${OUT_DIR}"

npc_runs=0
npc_pass=0
queue_runs=0
queue_pass=0
overflow_runs=0
overflow_pass=0
budget_runs=0
budget_pass=0

for i in $(seq 1 "${RUNS}"); do
  run_csv="${RAW_DIR}/run_${i}.csv"
  npc_log="${ANALYSIS_DIR}/run_${i}_npc_fairness.log"
  queue_log="${ANALYSIS_DIR}/run_${i}_area_queue_fairness.log"

  echo "[INFO] Run ${i}/${RUNS}"
  cp "${SOURCE_FIXTURE}" "${run_csv}"

  if python3 "${NPC_ANALYZER}" --input "${run_csv}" >"${npc_log}" 2>&1; then
    npc_status="PASS"
    ((npc_pass += 1))
  else
    npc_status="FAIL"
  fi
  ((npc_runs += 1))
  echo "[INFO] run_${i}: npc_fairness=${npc_status} (${npc_log})"

  if head -n1 "${run_csv}" | rg -q "processed_low"; then
    if python3 "${QUEUE_ANALYZER}" --input "${run_csv}" "${QUEUE_FLAGS[@]}" >"${queue_log}" 2>&1; then
      queue_status="PASS"
      ((queue_pass += 1))
    else
      queue_status="FAIL"
    fi
    ((queue_runs += 1))
    echo "[INFO] run_${i}: area_queue_fairness=${queue_status} (${queue_log})"
  else
    echo "[INFO] run_${i}: area_queue_fairness=SKIP (fixture has no processed_* columns)"
  fi

  overflow_result="$(python3 - "${run_csv}" <<'PY'
import csv,sys
path=sys.argv[1]
running=0
overflow=0
with open(path,encoding='utf-8',newline='') as f:
    reader=csv.DictReader(f)
    if 'overflow_events' not in (reader.fieldnames or []):
        print('NA')
        raise SystemExit(0)
    for row in reader:
        if (row.get('lifecycle_state') or '').strip().upper()!='RUNNING':
            continue
        running += 1
        try:
            if int(row.get('overflow_events') or '0')>0:
                overflow += 1
        except Exception:
            print('FAIL')
            raise SystemExit(0)
print('PASS' if running>0 and overflow>0 else 'FAIL')
PY
)"
  if [[ "${overflow_result}" != "NA" ]]; then
    ((overflow_runs += 1))
    if [[ "${overflow_result}" == "PASS" ]]; then
      ((overflow_pass += 1))
    fi
  fi

  budget_result="$(python3 - "${run_csv}" <<'PY'
import csv,sys
path=sys.argv[1]
running=0
budget=0
deferred=0
with open(path,encoding='utf-8',newline='') as f:
    reader=csv.DictReader(f)
    fields=set(reader.fieldnames or [])
    if 'budget_overrun' not in fields or 'deferred_events' not in fields:
        print('NA')
        raise SystemExit(0)
    for row in reader:
        if (row.get('lifecycle_state') or '').strip().upper()!='RUNNING':
            continue
        running += 1
        try:
            if int(row.get('budget_overrun') or '0')>0:
                budget += 1
            if int(row.get('deferred_events') or '0')>0:
                deferred += 1
        except Exception:
            print('FAIL')
            raise SystemExit(0)
print('PASS' if running>0 and budget>0 and deferred>0 else 'FAIL')
PY
)"
  if [[ "${budget_result}" != "NA" ]]; then
    ((budget_runs += 1))
    if [[ "${budget_result}" == "PASS" ]]; then
      ((budget_pass += 1))
    fi
  fi
done

overflow_status="N/A"
overflow_note="No overflow_events data in selected fixtures."
if (( overflow_runs > 0 )); then
  if (( overflow_pass == overflow_runs )); then
    overflow_status="PASS"
    overflow_note="overflow_events observed in all ${overflow_runs}/${overflow_runs} runs."
  else
    overflow_status="FAIL"
    overflow_note="overflow_events missing in $((overflow_runs - overflow_pass)) of ${overflow_runs} runs."
  fi
fi

budget_status="N/A"
budget_note="No budget_overrun/deferred_events data in selected fixtures."
if (( budget_runs > 0 )); then
  if (( budget_pass == budget_runs )); then
    budget_status="PASS"
    budget_note="budget_overrun+deferred tail observed in all ${budget_runs}/${budget_runs} runs."
  else
    budget_status="FAIL"
    budget_note="budget_overrun/deferred signal missing in $((budget_runs - budget_pass)) of ${budget_runs} runs."
  fi
fi

fairness_status="N/A"
fairness_note="No fairness fixtures with processed_* columns in selected profile."
if (( queue_runs > 0 )); then
  if (( queue_pass == queue_runs )); then
    fairness_status="PASS"
    fairness_note="Mandatory area-queue fairness flags passed in all ${queue_runs}/${queue_runs} runs."
  else
    fairness_status="FAIL"
    fairness_note="Area-queue fairness failed in $((queue_runs - queue_pass)) of ${queue_runs} runs."
  fi
fi

cat > "${OUT_DIR}/summary.md" <<MD
# NPC Bhvr Baseline Summary

- Timestamp: ${TIMESTAMP}
- Scenario/profile: ${SCENARIO}
- Source fixture: ${SOURCE_FIXTURE}
- Runs: ${RUNS}

## Analyzer post-processing

- analyze_npc_fairness.py: ${npc_pass}/${npc_runs} PASS.
- analyze_area_queue_fairness.py: ${queue_pass}/${queue_runs} PASS (when applicable).
- Mandatory fairness flags: ${QUEUE_FLAGS[*]}.

Logs per run are stored in ${ANALYSIS_DIR}.

## Guardrail checklist (PASS/FAIL)

| Guardrail | Result | Evidence |
| --- | --- | --- |
$(profile_guardrail_status "${SCENARIO}" "${overflow_status}" "${budget_status}" "${fairness_status}" "${overflow_note}" "${budget_note}" "${fairness_note}")

## One-step examples

    # Legacy baseline scenarios
    bash scripts/run_npc_bench.sh steady
    bash scripts/run_npc_bench.sh burst
    bash scripts/run_npc_bench.sh starvation-risk

    # Audit-derived profiles
    bash scripts/run_npc_bench.sh overflow-guardrail
    bash scripts/run_npc_bench.sh tick-budget
    bash scripts/run_npc_bench.sh fairness-checks
MD

echo "[OK] Benchmark scaffolding completed: ${OUT_DIR}"
