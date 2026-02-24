# NPC Baseline Report (Phase 1)

> Этот файл (`docs/perf/npc_baseline_report.md`) используется perf-gate как current reference-point.
> `docs/perf/reports/` используется только как historical archive baseline-отчётов.

## 1. Контекст последнего валидного прогона
- Дата: **2026-02-24**.
- Commit SHA: **60a5091**.
- Ветка: **work**.
- Окружение (локально/CI): **локально, fixture-driven прогон (`scripts/run_npc_bench.sh`)**.
- Конфигурация стенда: **Linux 6.12.47 x86_64, Python 3.10.19, RUNS=3 на сценарий**.

## 2. Сценарии и длительность
- steady: 3 прогона (`benchmarks/npc_baseline/results/20260224_090130`).
- burst: 3 прогона (`benchmarks/npc_baseline/results/20260224_090137`).
- pause-resume (profile `fairness-checks`): 3 прогона (`benchmarks/npc_baseline/results/20260224_090145`).
- fault profile `tick-budget-degraded`: 3 прогона (`benchmarks/npc_baseline/results/20260224_090154`).

## 3. Агрегированные метрики (минимум 3 прогона)

Пороги взяты из `docs/perf/npc_perf_plan.md` / `docs/perf/npc_perf_gate.md`.

| Scenario | area-tick p95 / p99 (ms) | queue depth p95 / p99 | deferred_rate | budget_overrun_rate | overflow_rate | Gate status |
|---|---:|---:|---:|---:|---:|---|
| steady | 6.00 / 6.00 | 11.05 / 12.00 | 0.05 | 0.00 | 0.00 | PASS |
| burst | 18.05 / 19.00 | 48.20 / 52.00 | 0.35 | 0.10 | 0.00 | PASS |
| pause-resume (`fairness-checks`) | N/A (fairness-only fixture) | N/A (fairness-only fixture) | N/A | N/A | N/A | PASS (`analyze_area_queue_fairness.py`: 3/3) |
| tick-budget-degraded | 21.05 / 22.00 | 91.20 / 95.00 | 0.75 | 0.65 | 0.25 | FAIL (превышены пороги p95/queue/deferred/overrun/overflow) |

## 4. Привязка baseline к guardrails

| Guardrail | Gate linkage | Current status |
|---|---|---|
| Registry overflow | `docs/perf/npc_perf_gate.md` + `run_npc_bench.sh` (`registry_overflow`) | FAIL (overflow_rate=0.25 в `tick-budget-degraded`) |
| Tick budget / degraded-mode | `docs/perf/npc_perf_gate.md` + `run_npc_bench.sh` (`tick_budget_degraded`) | FAIL (budget_overrun_rate=0.65, deferred_rate=0.75 в degraded) |
| Automated fairness | `docs/perf/npc_perf_gate.md` + `run_npc_bench.sh` (`automated_fairness`) | PASS (pause/resume fairness profile: 3/3) |

## 5. Baseline freshness policy
- Для perf-gate сравнений baseline должен быть **не старше 14 дней**.
- Если актуальный baseline старше 14 дней или отсутствует, сравнение считается **невалидным** (статус `BLOCKED`) до повторного baseline-прогона.
- Для публикации нового baseline обязательны:
  - минимум 3 прогона на сценарий;
  - фиксация даты, commit SHA, окружения и агрегированных метрик;
  - архивирование предыдущего current baseline в `docs/perf/reports/YYYY-MM-DD_*`.

## 6. Вывод (go/no-go)
- Решение: **NO-GO (FAIL)**.
- Обоснование: baseline свежий и валидный, но профиль `tick-budget-degraded` не проходит пороги из perf-plan/perf-gate.
- Rollback/mitigation: оптимизировать degraded-mode path (budget/deferred/overflow), затем повторить baseline-run и обновить `docs/perf/reports/npc_gate_summary_latest.md`.
