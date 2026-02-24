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
BASELINE_FILE="docs/perf/npc_baseline_report.md"

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
    overflow-guardrail|tick-budget|tick-budget-degraded)
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

is_guardrail_enabled() {
  local profile="$1"
  local guardrail="$2"
  case "${profile}:${guardrail}" in
    steady:fairness)
      echo "true"
      ;;
    burst:budget|burst:fairness)
      echo "true"
      ;;
    starvation-risk:overflow|starvation-risk:budget|starvation-risk:fairness)
      echo "true"
      ;;
    overflow-guardrail:overflow|tick-budget:budget|tick-budget-degraded:budget|fairness-checks:fairness)
      echo "true"
      ;;
    *)
      echo "false"
      ;;
  esac
}

check_baseline_freshness() {
  python3 - "${BASELINE_FILE}" <<'PY'
import re
import sys
from datetime import datetime, timezone

path = sys.argv[1]
try:
    text = open(path, encoding="utf-8").read()
except OSError:
    print("BLOCKED|baseline file not found")
    raise SystemExit(0)

match = re.search(r"- Дата:\s*\*\*(.+?)\*\*", text)
if not match:
    print("BLOCKED|baseline date field is missing")
    raise SystemExit(0)

raw = match.group(1).strip()
if raw.upper() == "N/A":
    print("BLOCKED|baseline date is N/A")
    raise SystemExit(0)

try:
    baseline_date = datetime.strptime(raw, "%Y-%m-%d").replace(tzinfo=timezone.utc)
except ValueError:
    print(f"BLOCKED|baseline date format is invalid: {raw}")
    raise SystemExit(0)

age_days = (datetime.now(timezone.utc) - baseline_date).days
if age_days > 14:
    print(f"BLOCKED|baseline older than 14 days ({age_days} days)")
else:
    print(f"FRESH|baseline age {age_days} days")
PY
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

baseline_info="$(check_baseline_freshness)"
baseline_state="${baseline_info%%|*}"
baseline_note="${baseline_info#*|}"

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

  cp "${SOURCE_FIXTURE}" "${run_csv}"

  if python3 "${NPC_ANALYZER}" --input "${run_csv}" >"${npc_log}" 2>&1; then
    ((npc_pass += 1))
  fi
  ((npc_runs += 1))

  if head -n1 "${run_csv}" | rg -q "processed_low"; then
    if python3 "${QUEUE_ANALYZER}" --input "${run_csv}" "${QUEUE_FLAGS[@]}" >"${queue_log}" 2>&1; then
      ((queue_pass += 1))
    fi
    ((queue_runs += 1))
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
    [[ "${overflow_result}" == "PASS" ]] && ((overflow_pass += 1))
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
    [[ "${budget_result}" == "PASS" ]] && ((budget_pass += 1))
  fi
done

summarize_guardrail() {
  local name="$1"
  local enabled="$2"
  local pass_count="$3"
  local total_count="$4"
  local unavailable_note="$5"

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

overflow_summary="$(summarize_guardrail "overflow" "$(is_guardrail_enabled "${SCENARIO}" overflow)" "${overflow_pass}" "${overflow_runs}" "overflow_events data absent in fixture")"
budget_summary="$(summarize_guardrail "budget" "$(is_guardrail_enabled "${SCENARIO}" budget)" "${budget_pass}" "${budget_runs}" "budget_overrun/deferred_events data absent in fixture")"
fairness_summary="$(summarize_guardrail "fairness" "$(is_guardrail_enabled "${SCENARIO}" fairness)" "${queue_pass}" "${queue_runs}" "processed_* columns absent in fixture")"

overflow_status="${overflow_summary%%|*}"; overflow_note="${overflow_summary#*|}"
budget_status="${budget_summary%%|*}"; budget_note="${budget_summary#*|}"
fairness_status="${fairness_summary%%|*}"; fairness_note="${fairness_summary#*|}"

if [[ "${baseline_state}" == "BLOCKED" ]]; then
  if [[ "${overflow_status}" == "PASS" ]]; then overflow_status="BLOCKED"; overflow_note="${overflow_note}; baseline ${baseline_note}"; fi
  if [[ "${budget_status}" == "PASS" ]]; then budget_status="BLOCKED"; budget_note="${budget_note}; baseline ${baseline_note}"; fi
  if [[ "${fairness_status}" == "PASS" ]]; then fairness_status="BLOCKED"; fairness_note="${fairness_note}; baseline ${baseline_note}"; fi
fi

cat > "${OUT_DIR}/gate_summary.csv" <<CSV
guardrail,status,scenario_id,profile,runs_passed,runs_total,evidence
registry_overflow,${overflow_status},${SCENARIO},${SCENARIO},${overflow_pass},${overflow_runs},"${overflow_note}"
tick_budget_degraded,${budget_status},${SCENARIO},${SCENARIO},${budget_pass},${budget_runs},"${budget_note}"
automated_fairness,${fairness_status},${SCENARIO},${SCENARIO},${queue_pass},${queue_runs},"${fairness_note}"
CSV

cat > "${OUT_DIR}/gate_summary.json" <<JSON
{
  "timestamp": "${TIMESTAMP}",
  "scenario_id": "${SCENARIO}",
  "source_fixture": "${SOURCE_FIXTURE}",
  "runs": ${RUNS},
  "baseline": {
    "status": "${baseline_state}",
    "note": "${baseline_note}",
    "reference": "${BASELINE_FILE}"
  },
  "guardrails": [
    {"id": "registry_overflow", "status": "${overflow_status}", "passed_runs": ${overflow_pass}, "total_runs": ${overflow_runs}, "evidence": "${overflow_note}"},
    {"id": "tick_budget_degraded", "status": "${budget_status}", "passed_runs": ${budget_pass}, "total_runs": ${budget_runs}, "evidence": "${budget_note}"},
    {"id": "automated_fairness", "status": "${fairness_status}", "passed_runs": ${queue_pass}, "total_runs": ${queue_runs}, "evidence": "${fairness_note}"}
  ]
}
JSON

cat > "${OUT_DIR}/summary.md" <<MD
# NPC Bhvr Baseline Summary

- Timestamp: ${TIMESTAMP}
- Scenario/profile: ${SCENARIO}
- Source fixture: ${SOURCE_FIXTURE}
- Runs: ${RUNS}
- Baseline reference: ${BASELINE_FILE} (${baseline_state}: ${baseline_note})

## Analyzer post-processing

- analyze_npc_fairness.py: ${npc_pass}/${npc_runs} PASS.
- analyze_area_queue_fairness.py: ${queue_pass}/${queue_runs} PASS (when applicable).
- Mandatory fairness flags: ${QUEUE_FLAGS[*]}.

Logs per run are stored in ${ANALYSIS_DIR}.

## Guardrail checklist (PASS/FAIL/BLOCKED)

| Guardrail | Result | Evidence |
| --- | --- | --- |
| Registry overflow guardrail | ${overflow_status} | ${overflow_note} |
| Tick budget / degraded-mode guardrail | ${budget_status} | ${budget_note} |
| Automated fairness checks | ${fairness_status} | ${fairness_note} |

## Machine-readable artifacts

- ${OUT_DIR}/gate_summary.csv
- ${OUT_DIR}/gate_summary.json
MD

echo "[OK] Benchmark scaffolding completed: ${OUT_DIR}"
echo "[OK] Gate summary: ${OUT_DIR}/gate_summary.json"
