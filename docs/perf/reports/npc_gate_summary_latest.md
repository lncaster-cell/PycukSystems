# NPC Gate Summary (latest snapshot)

Источник данных для этого snapshot:
- `docs/perf/npc_baseline_report.md` (baseline freshness/reference-point)
- `docs/perf/npc_perf_gate.md` (guardrail criteria)
- Актуальный отчёт: `docs/perf/reports/2026-02-24_npc_gate_report.md`

## Overall baseline linkage

- Baseline reference: `docs/perf/npc_baseline_report.md`
- Baseline freshness: **FRESH** (`Дата = 2026-02-24`)
- Итог: baseline-связка активна; guardrails имеют фактические статусы (PASS/FAIL), без `BLOCKED`.

## Guardrail status table

| Guardrail | Scenario IDs / profiles | Raw check status | Baseline linkage | Final gate status | Notes |
|---|---|---|---|---|---|
| Registry overflow guardrail | `tick-budget-degraded` (overflow observed) | FAIL | FRESH | **FAIL** | overflow_rate=0.25 > 0.02 threshold. |
| Tick budget / degraded-mode | `burst`, `tick-budget-degraded` | FAIL | FRESH | **FAIL** | degraded: budget_overrun_rate=0.65, deferred_rate=0.75. |
| Automated fairness checks | `fairness-checks` (pause/resume) | PASS | FRESH | **PASS** | queue fairness analyzer: 3/3 PASS. |
| Route cache warmup/rescan | `warmup-rescan` | PASS | FRESH | **PASS** | route_cache_warmup_rescan: 3/3 PASS, guardrail_status=PASS. |

## Machine-readable mirrors

Для каждого runtime-прогона `scripts/run_npc_bench.sh` публикуются:
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.csv`
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.json`

Этот файл — репозиторный «latest snapshot» для review/readability.
