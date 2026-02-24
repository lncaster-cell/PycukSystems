# NPC Baseline Report (Phase 1)

> Этот файл (`docs/perf/npc_baseline_report.md`) используется perf-gate как current reference-point.
> `docs/perf/reports/` используется только как historical archive baseline-отчётов.

## 1. Контекст последнего валидного прогона
- Дата: **2026-02-24**.
- Commit SHA: **290ab36** (`290ab36491c481e71e8cd0d16438b48a43f7463b`).
- Ветка: **work**.
- Окружение (локально/CI): **локально, fixture-driven прогон (`scripts/run_npc_bench.sh`)**.
- Конфигурация стенда: **Linux 6.12.47 x86_64, Python 3.10.19, RUNS=3 на сценарий**.

## 2. Сценарии и длительность
- steady: 3 прогона (`benchmarks/npc_baseline/results/20260224_092127`).
- burst: 3 прогона (`benchmarks/npc_baseline/results/20260224_092134`).
- starvation-risk: 3 прогона (`benchmarks/npc_baseline/results/20260224_092142`).
- overflow-guardrail: 3 прогона (`benchmarks/npc_baseline/results/20260224_092150`).
- tick-budget: 3 прогона (`benchmarks/npc_baseline/results/20260224_092158`).
- tick-budget-degraded: 3 прогона (`benchmarks/npc_baseline/results/20260224_092206`).
- fairness-checks: 3 прогона (`benchmarks/npc_baseline/results/20260224_092214`).

## 3. Агрегированные метрики (минимум 3 прогона)

Пороги взяты из `docs/perf/npc_perf_plan.md` / `docs/perf/npc_perf_gate.md`.

| Scenario | area-tick p95 / p99 (ms) | queue depth p95 / p99 | deferred_rate | budget_overrun_rate | overflow_rate | Gate status |
|---|---:|---:|---:|---:|---:|---|
| steady | 6.00 / 6.00 | 11.05 / 12.00 | 0.05 | 0.00 | 0.00 | PASS |
| burst | 18.05 / 19.00 | 48.20 / 52.00 | 0.35 | 0.10 | 0.00 | PASS |
| starvation-risk | 20.00 / 20.00 | 88.00 / 92.00 | 0.70 | 0.60 | 0.20 | PASS (guardrail-сигналы присутствуют в 3/3) |
| overflow-guardrail | 20.00 / 20.00 | 88.00 / 92.00 | 0.70 | 0.60 | 0.20 | PASS (overflow guardrail: 3/3) |
| tick-budget | 20.00 / 20.00 | 88.00 / 92.00 | 0.70 | 0.60 | 0.20 | PASS (budget/deferred signals: 3/3) |
| tick-budget-degraded | 20.00 / 20.00 | 88.00 / 92.00 | 0.70 | 0.60 | 0.20 | PASS (budget/deferred signals: 3/3) |
| fairness-checks | N/A (fairness-only fixture) | N/A (fairness-only fixture) | N/A | N/A | N/A | PASS (`analyze_area_queue_fairness.py`: 3/3) |

## 4. Привязка baseline к guardrails

| Guardrail | Gate linkage | Current status |
|---|---|---|
| Registry overflow | `docs/perf/npc_perf_gate.md` + `run_npc_bench.sh` (`registry_overflow`) | PASS (`starvation-risk` и `overflow-guardrail`: 3/3) |
| Tick budget / degraded-mode | `docs/perf/npc_perf_gate.md` + `run_npc_bench.sh` (`tick_budget_degraded`) | PASS (`burst`/`starvation-risk`/`tick-budget*`: сигналы 3/3) |
| Automated fairness | `docs/perf/npc_perf_gate.md` + `run_npc_bench.sh` (`automated_fairness`) | PASS (`fairness-checks`: 3/3) |

## 5. Baseline freshness policy
- Для perf-gate сравнений baseline должен быть **не старше 14 дней**.
- Если актуальный baseline старше 14 дней или отсутствует, сравнение считается **невалидным** (статус `BLOCKED`) до повторного baseline-прогона.
- Для публикации нового baseline обязательны:
  - минимум 3 прогона на сценарий;
  - фиксация даты, commit SHA, окружения и агрегированных метрик;
  - архивирование предыдущего current baseline в `docs/perf/reports/YYYY-MM-DD_*`.

## 6. Вывод (go/no-go)
- Решение: **GO (PASS)**.
- Обоснование: baseline свежий и валидный, все активные guardrails прошли на актуальных fixture-driven прогонах.
- Next-step: повторить прогон на runtime-telemetry dataset после следующего изменения budget/degraded-path.
