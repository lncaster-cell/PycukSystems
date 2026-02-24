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
| Registry overflow guardrail | `starvation-risk`, `overflow-guardrail` | PASS | FRESH | **PASS** | `run_npc_bench.sh`: 3/3 PASS в обоих профилях. |
| Tick budget / degraded-mode | `burst`, `starvation-risk`, `tick-budget`, `tick-budget-degraded` | PASS | FRESH | **PASS** | budget/deferred сигналы присутствуют: 3/3 в каждом профиле. |
| Automated fairness checks | `fairness-checks` (pause/resume) | PASS | FRESH | **PASS** | queue fairness analyzer: 3/3 PASS. |
| Route cache warmup/rescan | `warmup-rescan` | PASS | FRESH | **PASS** | route_cache_warmup_rescan: 3/3 PASS, guardrail_status=PASS. |

## Machine-readable mirrors

Для каждого runtime-прогона `scripts/run_npc_bench.sh` публикуются:
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.csv`
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.json`

Этот файл — репозиторный «latest snapshot» для review/readability.
