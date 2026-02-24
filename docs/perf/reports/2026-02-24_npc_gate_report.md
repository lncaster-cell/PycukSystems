# NPC Gate Report — 2026-02-24

## Sources
- Perf plan: `docs/perf/npc_perf_plan.md`
- Perf gate criteria: `docs/perf/npc_perf_gate.md`
- Current baseline reference-point: `docs/perf/npc_baseline_report.md`

## Run matrix (>=3 runs each)
- `steady` → `benchmarks/npc_baseline/results/20260224_090130`
- `burst` → `benchmarks/npc_baseline/results/20260224_090137`
- `pause-resume` (mapped to `fairness-checks`) → `benchmarks/npc_baseline/results/20260224_090145`
- `tick-budget-degraded` → `benchmarks/npc_baseline/results/20260224_090154`

## Aggregated results

| Scenario | p95 / p99 latency (ms) | p95 / p99 queue | deferred_rate | overrun_rate | overflow_rate | Status vs thresholds |
|---|---:|---:|---:|---:|---:|---|
| steady | 6.00 / 6.00 | 11.05 / 12.00 | 0.05 | 0.00 | 0.00 | PASS |
| burst | 18.05 / 19.00 | 48.20 / 52.00 | 0.35 | 0.10 | 0.00 | PASS (на границе deferred/overrun) |
| pause-resume (`fairness-checks`) | N/A | N/A | N/A | N/A | N/A | PASS (queue fairness analyzer 3/3) |
| tick-budget-degraded | 21.05 / 22.00 | 91.20 / 95.00 | 0.75 | 0.65 | 0.25 | FAIL |

## Raw artifacts (рядом с отчётом)
Сырые CSV/логи/summary сохранены рядом с отчётом в каталоге:
- `docs/perf/reports/2026-02-24_artifacts/20260224_090130`
- `docs/perf/reports/2026-02-24_artifacts/20260224_090137`
- `docs/perf/reports/2026-02-24_artifacts/20260224_090145`
- `docs/perf/reports/2026-02-24_artifacts/20260224_090154`

## Gate decision
**NO-GO (FAIL)**: baseline теперь свежий, но пороги degraded-профиля не пройдены.
