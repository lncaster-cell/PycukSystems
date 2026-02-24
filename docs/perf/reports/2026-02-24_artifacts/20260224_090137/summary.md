# NPC Bhvr Baseline Summary

- Timestamp: 20260224_090137
- Scenario/profile: burst
- Source fixture: docs/perf/fixtures/npc/burst.csv
- Runs: 3
- Baseline reference: docs/perf/npc_baseline_report.md (BLOCKED: baseline date is N/A)

## Analyzer post-processing

- analyze_npc_fairness.py: 3/3 PASS.
- analyze_area_queue_fairness.py: 0/0 PASS (when applicable).
- Mandatory fairness flags: --max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2.

Logs per run are stored in benchmarks/npc_baseline/results/20260224_090137/analysis.

## Guardrail checklist (PASS/FAIL/BLOCKED)

| Guardrail | Result | Evidence |
| --- | --- | --- |
| Registry overflow guardrail | N/A | Not part of selected profile |
| Tick budget / degraded-mode guardrail | BLOCKED | 3/3 runs passed; baseline baseline date is N/A |
| Automated fairness checks | N/A | processed_* columns absent in fixture |

## Machine-readable artifacts

- benchmarks/npc_baseline/results/20260224_090137/gate_summary.csv
- benchmarks/npc_baseline/results/20260224_090137/gate_summary.json
