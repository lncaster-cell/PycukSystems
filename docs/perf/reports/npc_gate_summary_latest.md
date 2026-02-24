# NPC Gate Summary (latest snapshot)

Источник данных для этого snapshot:
- `docs/perf/npc_baseline_report.md` (baseline freshness/reference-point)
- `docs/perf/npc_perf_gate.md` (guardrail criteria)

## Overall baseline linkage

- Baseline reference: `docs/perf/npc_baseline_report.md`
- Baseline freshness: **BLOCKED** (`Дата = N/A`)
- Итог: все guardrails, требующие baseline-сравнения, маркируются `BLOCKED`.

## Guardrail status table

| Guardrail | Scenario IDs / profiles | Raw check status | Baseline linkage | Final gate status | Notes |
|---|---|---|---|---|---|
| Registry overflow guardrail | `starvation-risk`, `overflow-guardrail` | PASS (скриптовый критерий определён) | BLOCKED | **BLOCKED** | Требуется свежий baseline-run (<=14 дней). |
| Tick budget / degraded-mode | `burst`, `starvation-risk`, `tick-budget`, `tick-budget-degraded` | PASS (скриптовый критерий определён) | BLOCKED | **BLOCKED** | Требуется fresh baseline и запись p95/p99. |
| Automated fairness checks | `steady`, `burst`, `starvation-risk`, `fairness-checks` + fault fixtures | PASS (self-check критерий определён) | BLOCKED | **BLOCKED** | До обновления baseline release-gate не может быть GO. |

## Machine-readable mirrors

Для каждого runtime-прогона `scripts/run_npc_bench.sh` публикуются:
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.csv`
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.json`

Этот файл — репозиторный «latest snapshot» для review/readability.
