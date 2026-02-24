# NPC Bhvr Baseline Summary

- Timestamp: 20260224_092219
- Scenario/profile: warmup-rescan
- Source fixture: docs/perf/fixtures/npc/warmup_rescan.csv
- Runs: 3
- Baseline reference: docs/perf/npc_baseline_report.md (FRESH: baseline age 0 days)

## Analyzer post-processing

- analyze_npc_fairness.py: 3/3 PASS.
- analyze_area_queue_fairness.py: 0/0 PASS (when applicable).
- Mandatory fairness flags: --max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2.

Logs per run are stored in benchmarks/npc_baseline/results/20260224_092219/analysis.

## Guardrail checklist (PASS/FAIL/BLOCKED)

| Guardrail | Result | Evidence |
| --- | --- | --- |
| Registry overflow guardrail | N/A | Not part of selected profile |
| Tick budget / degraded-mode guardrail | N/A | Not part of selected profile |
| Automated fairness checks | N/A | Not part of selected profile |
| Route cache warmup/rescan guardrail | PASS | 3/3 runs passed |

## Machine-readable artifacts

- benchmarks/npc_baseline/results/20260224_092219/gate_summary.csv
- benchmarks/npc_baseline/results/20260224_092219/gate_summary.json
